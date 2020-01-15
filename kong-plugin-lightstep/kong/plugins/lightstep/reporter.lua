local resty_http = require "resty.http"
local to_hex = require "resty.string".to_hex
local cjson = require "cjson".new()
cjson.encode_number_precision(16)

local floor = math.floor
local gsub = string.gsub

local lightstep_reporter_methods = {}
local lightstep_reporter_mt = {
  __name = "kong.plugins.lightstep.reporter",
  __index = lightstep_reporter_methods
}

local function new_lightstep_reporter(config)
  local collector_host = config.collector_host
  local collector_port = config.collector_port
  local component_name = config.component_name
  local access_token = config.access_token
  
  return setmetatable({
    component_name = component_name,
    collector_host = collector_host,
    collector_port = collector_port,
    access_token = access_token,
    pending_spans = {},
    pending_spans_n = 0
  }, lightstep_reporter_mt)
end

local span_kind_map = {
  client = "client",
  server = "server",
  producer = "producer",
  consumer = "consumer",
}

local function bin_to_int(id)
  return string.format("%.0f",tonumber(string.sub(to_hex(id),0,16),16))
end


function lightstep_reporter_methods:report(span)
  local spanCtx = span:context()

  -- Tags
  local lightstep_tags = {}
  for k, v in span:each_tag() do
    if v ~= "" then 
      -- TODO: actual keys instead of all string
      local tmp = { key = k, stringValue = tostring(v)}
      table.insert( lightstep_tags, tmp )
    end
  end

  -- Logs
  local lightstep_logs do
    local n_logs = span.n_logs
    if n_logs > 0 then
      lightstep_logs = kong.table.new(n_logs, 0)
      for i = 1, n_logs do
        local log = span.logs[i]
        lightstep_logs[i] = {
          timestamp = tostring(os.date("!%Y-%m-%dT%TZ",floor(log.timestamp))),
          fields = {{
            key = log.key,
            stringValue = log.value
          }}
        }
      end
    end
  end

  if not next(lightstep_tags) then
    lightstep_tags = nil
  end

  local ref = spanCtx.parent_id and bin_to_int(spanCtx.parent_id) or nil

  local lightstep_span = {
    -- TODO: check for uint64
    span_context = {
      trace_id = bin_to_int(spanCtx.trace_id),
      span_id = bin_to_int(spanCtx.span_id),
      --  TODO: baggage
    },
    operation_name = span.name,
    references = ref and {{
      relationship = 'CHILD_OF',
      span_context = {
        trace_id = bin_to_int(spanCtx.trace_id),
        span_id = ref
      }
    }} or nil,
    start_timestamp = tostring(os.date("!%Y-%m-%dT%TZ",floor(span.timestamp))),
    duration_micros = floor(span.duration * 1000000),
    tags = lightstep_tags,
    logs = lightstep_logs,
  }

  local i = self.pending_spans_n + 1
  self.pending_spans[i] = lightstep_span
  self.pending_spans_n = i
end

function lightstep_reporter_methods:flush()
  if self.pending_spans_n == 0 then
    return true
  end

  local pending_spans = self.pending_spans
  self.pending_spans = {}
  self.pending_spans_n = 0

  local report = {
    auth = {
      access_token = self.access_token
    },
    reporter = {
      -- TODO: get the right reporter id
      reporter_id = "1234",
      tags = { {
          key = 'lightstep.component_name',
          stringValue = self.component_name
        } }
    },
    spans = pending_spans
  }

  local httpc = resty_http.new()
  -- TODO: support https based on collector_encryption parameter
  local protocol = 'http'
  local res, err = httpc:request_uri((protocol .. "://" .. self.collector_host .. ":" .. self.collector_port .. "/api/v2/reports"), {
    method = "POST",
    headers = {
      ["content-type"] = "application/json",
      ["accept"] = "application/json"
    },
    body = cjson.encode(report)
  })

  if not res then 
    return nil, "Failed to send request: " .. err
  elseif res.status < 200 or res.status >= 300 then 
    return nil, "Failed: " .. res.status .. " " .. res.reason .. " " .. res.body
  end
  return true
end

return {
  new = new_lightstep_reporter,
}