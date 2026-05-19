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

resource "verda_container" "small3-2" {
  name = "mistral-small3-2-aladok40"

  compute = {
    name = "H100"
    size = 1
  }

  is_spot = true

  scaling = {
    min_replica_count               = 0
    max_replica_count               = 1
    queue_message_ttl_seconds       = 600
    concurrent_requests_per_replica = 40

    queue_load = {
      threshold = 5
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
      ]

      volume_mounts = [
        {
          mount_path = "/data",
          size_gb    = 150,
          type       = "scratch"
        }
      ]

      entrypoint_overrides = {
        enabled = true
        cmd = [
          "stelterlab/Mistral-Small-3.2-24B-Instruct-2506-FP8",
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
          "--enable-prefix-caching",
          "--enable-chunked-prefill",
          "--max_num_batched_tokens", "8192",
        ],
      }
    }
  ]
}

output "container_url" {
  value = verda_container.small3-2.endpoint_base_url
}



resource "verda_container" "serving-gpt-oss-120b-sglang" {
  name = "gpt-oss-120b-sglang-al2309zc"

  compute = {
    name = "H200"
    size = 1
  }

  is_spot = true

  scaling = {
    min_replica_count               = 0
    max_replica_count               = 1
    queue_message_ttl_seconds       = 600
    concurrent_requests_per_replica = 40

    queue_load = {
      threshold = 2
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
      image        = "lmsysorg/sglang:v0.5.10rc0"
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
        { type = "plain", name = "NCCL_DEBUG", value_or_reference_to_secret = "WARN" },
        { type = "plain", name = "NCCL_P2P_LEVEL", value_or_reference_to_secret = "SYS" },
      ]

      volume_mounts = [
        {
          mount_path = "/data",
          size_gb    = 150,
          type       = "scratch"
        },
        {
          mount_path = "/dev/shm",
          size_in_mb = 32768,
          type       = "memory"
        }
      ]

      entrypoint_overrides = {
        enabled = true
        cmd = [
          "python3", "-m", "sglang.launch_server",
          "--model-path", "openai/gpt-oss-120b",
          "--host", "0.0.0.0",
          "--port", "8000",
          "--reasoning-parser", "gpt-oss",
          "--speculative-algorithm", "EAGLE3",
          "--speculative-draft-model-path", "lmsys/EAGLE3-gpt-oss-120b-bf16",
          "--speculative-num-steps", "3",
          "--speculative-eagle-topk", "1",
          "--speculative-num-draft-tokens", "4",
        ],
      }
    }
  ]
}

output "gpt_oss_120b_sglang_endpoint_url" {
  value = verda_container.serving-gpt-oss-120b-sglang.endpoint_base_url
}
