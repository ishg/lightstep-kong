local new_tracer = require "opentracing.tracer".new
local lightstep_codec = require "kong.plugins.lightstep.codec"
local new_random_sampler = require "kong.plugins.lightstep.random_sampler".new
local new_lightstep_reporter = require "kong.plugins.lightstep.reporter".new
local OpenTracingHandler = require "kong.plugins.lightstep.opentracing"

local LightStepLogHandler = OpenTracingHandler:extend()
LightStepLogHandler.VERSION = "0.1.0"

function LightStepLogHandler.new_tracer(config)
  local tracer = new_tracer(new_lightstep_reporter(config), new_random_sampler(config))
  tracer:register_injector("http_headers", lightstep_codec.new_injector())
  tracer:register_extractor("http_headers", lightstep_codec.new_extractor(kong.log.warn))
  return tracer
end

local function log(premature, reporter)
  if premature then
    return
  end

  local ok, err = reporter:flush()
  if not ok then
    kong.log.err("reporter flush ", err)
    return
  end
  kong.log("reporter flush", "success")
end

function LightStepLogHandler:log(config)
  LightStepLogHandler.super.log(self, config)

  local tracer = self:get_tracer(config)
  local lightstep_reporter = tracer.reporter -- XXX: not guaranteed by opentracing-lua?
  local ok, err = ngx.timer.at(0, log, lightstep_reporter)
  if not ok then
    kong.log.err("failed to create timer: ", err)
  end
end

return LightStepLogHandler