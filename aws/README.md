## Commands executed

```
cp variables.hcl.example variables.hcl
# modify variables.hcl
```


```
# set AWS creds in environment
packer init image.pkr.hcl
packer build -var-file=variables.hcl image.pkr.hcl

# get the AMI variable and update "ami" in variables.hcl
```


```
# initialize terraform
terraform init
terraform apply -var-file=variables.hcl
```

```
./post-setup.sh
```


### Destroy resources

To destroy, run

```
terraform destroy -var-file=variables.hcl
```

Make sure AWS creds are available as env variables.