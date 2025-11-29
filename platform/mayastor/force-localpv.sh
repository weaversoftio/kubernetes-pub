#!/bin/sh

# ================================================
# Helm Post-Renderer for Mayastor LocalPV
# Forces the localpv-provisioner to run ONLY on tools nodes
# Compatible with yq v4.x
# ================================================

# Read all YAML input from Helm
yq eval '
  (. | select(.kind == "Deployment" and .metadata.name == "mayastor-localpv-provisioner")) |= (
      .spec.template.spec.nodeSelector = {
        "dedicated": "tools",
        "node-type": "tools"
      }
      |
      .spec.template.spec.tolerations = [
        {
          "key": "dedicated",
          "operator": "Equal",
          "value": "tools",
          "effect": "NoSchedule"
        }
      ]
      |
      .spec.template.spec.affinity = {
        "nodeAffinity": {
          "requiredDuringSchedulingIgnoredDuringExecution": {
            "nodeSelectorTerms": [
              {
                "matchExpressions": [
                  {
                    "key": "dedicated",
                    "operator": "In",
                    "values": ["tools"]
                  },
                  {
                    "key": "kubernetes.io/hostname",
                    "operator": "NotIn",
                    "values": ["worker4","worker5"]
                  }
                ]
              }
            ]
          }
        }
      }
  )
' -
