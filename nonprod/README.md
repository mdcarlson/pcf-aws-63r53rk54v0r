# nonprod foundation

Deployed using (Platform Automation)[http://docs.pivotal.io/platform-automation/v2.1/index.html] via the Control Plane at (cp.aws.63r53rk54v0r.com)[../cp/README.md]

Specs include:
- Ops Manager 2.4.x
- Control Plane 0.0.27
- PAS 2.4.x
- Healthwatch 1.5.x

## X. Generate SSL certificates

1. Generate certs using
    ```
    sudo certbot --server https://acme-v02.api.letsencrypt.org/directory \
    -d nonprod.aws.63r53rk54v0r.com \
    -d '*.nonprod.aws.63r53rk54v0r.com' \
    -d '*.apps.nonprod.aws.63r53rk54v0r.com' \
    -d '*.sys.nonprod.aws.63r53rk54v0r.com' \
    -d '*.login.sys.nonprod.aws.63r53rk54v0r.com' \
    -d '*.uaa.sys.nonprod.aws.63r53rk54v0r.com' \
    --manual --preferred-challenges dns-01 certonly
    ```

## X. Pave the IaaS

Terraform IaaS by
1. `cd terraforming`
1. `terraform plan -out=plan`
1. `terraform apply plan`
1. Capture opsman ssh key by
    1. `terraform output ops_manager_ssh_private_key > ../opsman.pem`
    1. `chmod 600 ../opsman.pem`

## X. Configure root DNS

In the root DNS Zone (Azure) add a NS record with values `terraform output env_dns_zone_name_servers` for name `nonprod.aws`.

## X. Populate Credhub with appropriate secrets

First we need to look up the appropriate client/secret for connecting to *Control Plane* Credhub from *BOSH* Credhub.
1. SSH into Control Plane Ops Manager
1. Run `export BOSH_ENVIRONMENT=10.0.16.5`
1. Run `credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert=/var/tempest/workspaces/default/root_ca_certificate`
1. Run `credhub login -u $UAA_ADMIN_USERNAME -p $UAA_ADMIN_PASSWORD`, where
    - `$UAA_ADMIN_USERNAME` and `$UAA_ADMIN_PASSWORD` come from https://pcf.cp.aws.63r53rk54v0r.com/api/v0/deployed/director/credentials/uaa_admin_user_credentials
1. Run `credhub get -n /p-bosh/control-plane/credhub_admin_client_password` -> `$CREDHUB_ADMIN_CLIENT_PASSWORD`

Log into Control Plane Credhub by
1. Run `credhub api -s plane.cp.aws.63r53rk54v0r.com:8844 --ca-cert=ca.pem`, where
    - `ca.pem` is the Lets Encrypt chain.pem
1. Run `credhub login --client-name=credhub_admin_client --client-secret=$CREDHUB_ADMIN_CLIENT_PASSWORD`

Populate Credhub with `nonprod` secret. See `nonprod_secrets.example.yml` as a guide.
1. Run `credhub import -f nonprod_secrets.yml`

## X. Download external dependencies

1. `fly login -t nonprod -c https://plane.cp.aws.63r53rk54v0r.com/ -n main`
1. `fly -t nonprod sp -p external-dependencies -c external-dependencies-pipeline.yml -l variables.yml`
1. `fly -t nonprod up -p external-dependencies`


## X. Install all things

1. `fly -t nonprod sp -p install-all-things -c install-all-things-pipeline.yml -l variables.yml`
1. `fly -t nonprod up -p install-all-things`

## X. Use nonprod

`cf push` etc

## X. Tear everything down

Delete the installation (products, BOSH Director, and Ops Manager) via:
1. `fly -t nonprod sp -p destroy-foundation -c destroy-foundation-pipeline.yml -l variables.yml`
1. `fly -t nonprod up -p destroy-foundation`
1. `fly -t nonprod tj -j destroy-foundation/destroy-foundation`

Unpave the IaaS via
1. `terraform destroy`

# TODOS

- create S3 buckets in control plane terraforming
- common descriptions/creation of Github repos and keys
- change to use CP credhub (not ops man credhub)
- use RDS for database instead of internal
- update certificates
- base pas configuration, with operations capturing features?