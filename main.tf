terraform {
  required_providers {
    verda = {
      source  = "verda-cloud/verda"
      version = "~> 1.0"
    }
  }
}

provider "verda" {}

variable "hf_token" {
  description = "HuggingFace token for model downloads"
  type        = string
  sensitive   = true
  default     = ""
}

variable "model" {
  description = "Model to serve"
  type        = string
  default     = "stelterlab/Mistral-Small-3.2-24B-Instruct-2506-FP8"
}

resource "verda_container" "serving" {
  name = "generative-agents-quantized-endpoint"

  compute = {
    name = "H100"
    size = 1
  }

  is_spot = true

  scaling = {
    min_replica_count               = 0
    max_replica_count               = 1
    queue_message_ttl_seconds       = 600
    concurrent_requests_per_replica = 20

    queue_load = {
      threshold = 10
    }

    scale_down_policy = {
      delay_seconds = 180
    }

    scale_up_policy = {
      delay_seconds = 240
    }
  }

  containers = [
    {
      image        = "vllm/vllm-openai:v0.17.1"
      exposed_port = 8000

      healthcheck = {
        enabled = "true"
        port    = "8000"
        path    = "/health"
      }

      env = [
        {
          type                         = "plain"
          name                         = "HF_TOKEN"
          value_or_reference_to_secret = var.hf_token
        },
        { type = "plain", name = "HF_HOME", value_or_reference_to_secret = "/data/.huggingface" },
        { type = "plain", name = "MODEL", value_or_reference_to_secret = var.model }
      ]

      volume_mounts = [{
        mount_path = "/data",
        size_gb    = 100,
        type       = "scratch"
      }]

      entrypoint_overrides = {
        enabled = true
        cmd = [
          var.model,
          "--gpu-memory-utilization", "0.93",
          "--max-model-len", "auto",
          "--tokenizer_mode", "mistral",
          "--config_format", "mistral",
          "--load_format", "mistral",
          "--tool-call-parser", "mistral",
          "--enable-auto-tool-choice",
          "--limit-mm-per-prompt", "{\"image\":10}",
          "--speculative-config", "{\"method\":\"ngram\",\"num_speculative_tokens\":5,\"prompt_lookup_max\":5}",
          "--model-loader-extra-config", "{\"enable_multithread_load\": true}",
          "--enable-prefix-caching"
        ],

      }
    }
  ]
}

output "container_url" {
  value = verda_container.serving.endpoint_base_url
}
