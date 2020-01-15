return {
  name = "lightstep",
  fields = { 
    { config = {
        type = "record",
        fields = {
          { 
            access_token = {
              type = "string",
              required = true,
              default = "none"
            }
          },
          {
            component_name = {
              type = "string",
              default = "lightstep-kong"
            }
          },        
          {
            collector_plaintext = {
              type = "boolean",
              default = false
            }
          },
          {
            collector_host = {
              type = "string",
              default = "ingest.lightstep.com"
            }
          },
          {
            collector_port = {
              type = "number",
              default = 443,
              between = {1, 65535}
            }
          },
          {
            sample_ratio = { 
              type = "number",
              default = 1,
              between = { 0, 1 } 
            }
          },
          {
            include_credential = {
              type = "boolean",
              default = false
            }
          },
        },
      },
    }, 
  },
}
