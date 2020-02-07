local to_hex = require "resty.string".to_hex
local new_span_context = require "opentracing.span_context".new

local function hex_to_char(c)
  return string.char(tonumber(c, 16))
end

local function from_hex(str)
  if str ~= nil then
    str = str:gsub("%x%x", hex_to_char)
  end
  return str
end

local function new_extractor(warn)
  return function(headers)
    local sample = headers["ot-tracer-sampled"]
    if sample == "1" or sample == "true" then
      sample = true
    elseif sample == "0" or sample == "false" then
      sample = false
    elseif sample ~= nil then
      warn("ot-tracer-sampled header invalid; ignoring.")
      sample = nil
    end

    local had_invalid_id = false
    local trace_id = headers["ot-tracer-traceid"]

    if trace_id and ((#trace_id ~= 16 and #trace_id ~= 43) or trace_id:match("%X")) then
      had_invalid_id = true
      warn("ot-tracer-traceid header invalid; ignoring.")
    end

    local request_span_id = headers["ot-tracer-spanid"]
    -- Validate request_span_id
    if request_span_id and (#request_span_id ~= 16 or request_span_id:match("%X")) then
      warn("ot-tracer-spanid header invalid; ignoring.")
      had_invalid_id = true
    end

    if trace_id == nil or had_invalid_id then
      return nil
    end

    local baggage = {}
    for k, v in pairs(headers) do
      local baggage_key = k:match("^ot-baggage%-(.*)$")
      if baggage_key then
        baggage[baggage_key] = ngx.unescape_uri(v)
      end
    end

    trace_id = from_hex(trace_id)
    request_span_id = from_hex(request_span_id)

    parent_span_id = nil

    return new_span_context(trace_id, request_span_id, parent_span_id, sample, baggage)
  end
end

local function new_injector()
  return function(span_context, headers)
    headers["ot-tracer-traceid"] = to_hex(span_context.trace_id)
    headers["ot-tracer-spanid"] = to_hex(span_context.span_id)
    headers["ot-tracer-sampled"] = (span_context.should_sample and "1" or "0") or nil
    for key, value in span_context:each_baggage_item() do
      headers["ot-baggage-"..key] = ngx.escape_uri(value)
    end
  end
end

return {
  new_extractor = new_extractor,
  new_injector = new_injector,
}