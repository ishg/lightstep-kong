package = "kong-plugin-lightstep"
version = "0.1.0-1"

source = {
  url = "https://github.com/ishg/lightstep-kong";
  dir = "kong-plugin-lightstep-0.1.0";
}

description = {
  summary = "This plugin allows Kong to propagate LightStep headers and report to a LightStep Satellite";
  homepage = "https://github.com/ishg/lightstep-kong";
  license = "Apache 2.0";
}

dependencies = {
  "lua >= 5.1";
  "lua-cjson";
  "lua-resty-http >= 0.11";
  "opentracing >= 0.0.2";
}

build = {
   type = "builtin";
   modules = {
      ["kong.plugins.lightstep.codec"] = "kong/plugins/lightstep/codec.lua";
      ["kong.plugins.lightstep.handler"] = "kong/plugins/lightstep/handler.lua";
      ["kong.plugins.lightstep.opentracing"] = "kong/plugins/lightstep/opentracing.lua";
      ["kong.plugins.lightstep.random_sampler"] = "kong/plugins/lightstep/random_sampler.lua";
      ["kong.plugins.lightstep.reporter"] = "kong/plugins/lightstep/reporter.lua";
      ["kong.plugins.lightstep.schema"] = "kong/plugins/lightstep/schema.lua";
   };
}
