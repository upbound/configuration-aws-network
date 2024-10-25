import file
import yaml

_composition = {
    apiVersion = "apiextensions.crossplane.io/v1"
    kind = "Composition"
    metadata = {
        name = "kcl.xnetworks.aws.platform.upbound.io"
        labels = {
            provider = "aws"
            function = "kcl"
        }
    }
    spec = {
        compositeTypeRef = {
            apiVersion = "aws.platform.upbound.io/v1alpha1"
            kind = "XNetwork"
        }
        mode = "Pipeline"
        pipeline = [
            {
                step = "kcl"
                functionRef = {
                    name = "crossplane-contrib-function-kcl"
                }
                input = {
                    apiVersion = "krm.kcl.dev/v1alpha1"
                    kind = "KCLInput"
                    spec = {
                        source = (file.read("apis/kcl/main.k"))
                    }
                }
            },
            {
                step = "automatically-detect-ready-composed-resources"
                functionRef = {
                    name = "crossplane-contrib-function-auto-ready"
                }
            }
        ]
    }
}

file.write("apis/kcl/composition.yaml", yaml.encode(_composition))
