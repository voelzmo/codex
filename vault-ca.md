## Building with Local Certificate Authority services

We are going to build root and an intermediate certificate 
authority services using vault running on the bastion host.

(assumption you are logged onto one of the user bastion accounts)

We do not want to lose our vault information so we are going to using
a file backend.   We are also going to enable memory locking without 
vault using root access.

```bash
cd $HOME
sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
mkdir vault
```

Now lets create our vault configuration file before we start up the server.
The secrets we will stored in the ~/vault/secrets directory.

```bash
cat >vault/vault.hcl <<EOF
disable_mlock  = false

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

backend "file" {
  path = "${HOME}/vault/secrets"
}
EOF
```

Now we start up vault using the configuration we just created. I am leaving the vault server in the forground, so we can see any errors that might happen.

```bash
vault server -config=${HOME}/vault/vault.hcl
```

Leave this session open and now open another session to the same user to 
carry out the remaining operations.

In the session we will initialize, unseal the vault and authorize. 
Remember to save your unseal keys and root token somehow safe.

```bash
export VAULT_ADDR=http://localhost:8200
vault init
# save those keys and root token
vault unseal             # use any key not used before
vault unseal             # ditto
vault unseal             # ditto
vault auth               # use your root token
vault status
```

Now we are going to setup the root CA service and certificate to have a ~ 10 year expiration.
Feel free  read about the pki backend if you want at https://www.vaultproject.io/docs/secrets/pki/ if want to know what that **exclude_cn_from_sans** means. 

```bash
vault mount -path=codex-root-ca -description="Codex Root CA" -max-lease-ttl=87648h pki
$ vault mounts
vault write codex-root-ca/root/generate/internal \
common_name="Codex Root Certificate" \
ttl=87648h \
key_bits=4096 \
exclude_cn_from_sans=true
```

We created our certificate. Now read it back and lets setup the internal url 
to use this CA service. You will need the internal ip address of the bastion hoset.

```bash
curl -s http://localhost:8200/v1/codex-root-ca/ca/pem | openssl x509 -text
vault write codex-root-ca/config/urls issuing_certificates="http://10.30.0.211:8200/v1/codex-root-ca"
```

curl -s http://localhost/








