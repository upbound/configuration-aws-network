import file
import yaml

getByCompositeResourceName = lambda name: str -> any {
   render = yaml.decode_all(file.read(file.read_env("RENDERED_COMPOSITION")))
   resource = [ el for el in render if el.metadata.annotations?["crossplane.io/composition-resource-name"] == name][0]
   resource
}

test_subnets = lambda {
   subnetPublic1 = getByCompositeResourceName("subnet-us-west-2a-192-168-0-0-18-public")
   assert subnetPublic1.metadata.labels.access == "public"
   assert subnetPublic1.spec.forProvider.mapPublicIpOnLaunch == True
   assert subnetPublic1.spec.forProvider.tags["networks.aws.platform.upbound.io/network-id"] == "configuration-aws-network"
   assert subnetPublic1.spec.forProvider.tags["kubernetes.io/role/elb"] == "1"

   subnetPublic2 = getByCompositeResourceName("subnet-us-west-2b-192-168-64-0-18-public")
   assert subnetPublic1.metadata.labels.access == "public"
   assert subnetPublic1.spec.forProvider.mapPublicIpOnLaunch == True
   assert subnetPublic1.spec.forProvider.tags["networks.aws.platform.upbound.io/network-id"] == "configuration-aws-network"
   assert subnetPublic1.spec.forProvider.tags["kubernetes.io/role/elb"] == "1"

   subnetPrivate1 = getByCompositeResourceName("subnet-us-west-2a-192-168-128-0-18-private")
   assert subnetPrivate1.metadata.labels.access == "private"
   assert subnetPrivate1.spec.forProvider.tags["kubernetes.io/role/internal-elb"] == "1"

   subnetPrivate2 = getByCompositeResourceName("subnet-us-west-2b-192-168-192-0-18-private")
   assert subnetPrivate2.metadata.labels.access == "private"
   assert subnetPrivate2.spec.forProvider.tags["kubernetes.io/role/internal-elb"] == "1"
}

test_rtas = lambda {
   rtaPublic1 = getByCompositeResourceName("rta-us-west-2a-192-168-0-0-18-public")
   assert rtaPublic1.spec.forProvider.subnetIdSelector.matchLabels.access == "public"

   rtaPublic2 = getByCompositeResourceName("rta-us-west-2b-192-168-64-0-18-public")
   assert rtaPublic2.spec.forProvider.subnetIdSelector.matchLabels.access == "public"

   rtaPrivate1 = getByCompositeResourceName("rta-us-west-2a-192-168-128-0-18-private")
   assert rtaPrivate1.spec.forProvider.subnetIdSelector.matchLabels.access == "private"

   rtaPrivate2 = getByCompositeResourceName("rta-us-west-2b-192-168-192-0-18-private")
   assert rtaPrivate2.spec.forProvider.subnetIdSelector.matchLabels.access == "private"
}
