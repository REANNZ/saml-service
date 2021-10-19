# SAML Service

AAF service responsible for Security Assertion Markup Language (SAML) data storage, metadata generation and inter-federation metadata processing.

## Local Development

SAML Service requires ruby installed through rbenv and a running instance of mysql.
If that's working, run `bin/setup` to prepare the application.
Then you can run `bundle exec rspec` to test the application and `rails server` to boot it.

## AAF Production Concerns

### eduGAIN

#### Publishing an AAF registered IdP

To export an AAF registered Identity Provider (IdP) to eduGAIN:

1. Get a session on `<SAML Service HOST>` 
1. Become the `saml` user, `$> sudo -iu saml`
1. Source `.app-env`
1. Change to `repository`
1. Run `rake edugain:publish_idp\['https://idp.example.edu.au/idp/shibboleth'\]` replacing `https://idp.example.edu/idp/shibboleth` with the target EntityID 

Sequel gem warnings, if any, can be ignored.

Validate the EntityID will now be pushlished to the global feed:

```
$> http https://saml.aaf.edu.au/mdq/aaf-edugain-export/entities Accept:application/samlmetadata+xml | rg 'https://idp.example.edu.au/idp/shibboelth'
```

Advise support all is complete. On our next Metadata publish this will be pushed out to S3 and will picked up and pushed out by global
metadata aggregate in around 24 hours. Check https://technical.edugain.org/entities to ensure it shows up after those 24 hours if necessary.

#### Publishing an AAF registered SP

To export an AAF registered Service Provider (SP) to eduGAIN:

1. Get a session on `<SAML Service Host>` 
1. Become the `saml` user, `$> sudo -iu saml`
1. Source `.app-env`
1. Change to `repository`
1. Run `rake edugain:publish_sp\['https://example.edu.au/shibboleth','https://example.edu.au/information_url'\]` replacing `https://example.edu/shibboleth` with the target EntityID 
   and `https://example.edu.au/information_url` with a public URL where potential service users can find out more information.

Sequel gem warnings, if any, can be ignored.

Optionally validate the EntityID will now be pushlished to the global feed:

```
$> http https://saml.aaf.edu.au/mdq/aaf-edugain-export/entities Accept:application/samlmetadata+xml | rg 'https://example.edu.au/shibboleth'
```

Advise support all is complete. On our next Metadata publish this will be pushed out to S3 and will picked up and pushed out by global
metadata aggregate in around 24 hours. Check https://technical.edugain.org/entities to ensure it shows up after those 24 hours if necessary.

#### Approving R&S SP from another federation
This is automatically handled by SAML Service.

AAF IdP will automatically release the [Research and Scholarship (R&S)](https://refeds.org/category/research-and-scholarship) bundle of attributes.

Services marked as R&S are preferred within the AAF context.

#### Approving a non R&S SP from another federation

To import a non AAF registered SP from eduGAIN that is not considered R&S do the following:

1. Get a session on `<SAML Service Host>` 
1. Become the `saml` user, `$> sudo -iu saml`
1. Source `.app-env`
1. Change to `repository`
1. Run `rake edugain:approve_non_rs_entity\['https://example.edu/shibboleth'\]` replacing `https://example.edu/shibboleth` with the target EntityID.

Sequel gem warnings, if any, can be ignored.

Optionally validate the EntityID will now be ingested from the global feed:

```
$> http https://saml.aaf.edu.au/mdq/aaf-edugain-verified/entities Accept:application/samlmetadata+xml | rg 'https://example.edu/shibboleth'
```

Advise support all is complete. On our next Metadata publish this will be pushed out to S3 and will picked up and loaded by AAF IdP the next time they
update metadata.

n.b. This process will NOT result in automated IdP attribute release. IdP admins must understand what data they are releasing to a service
and explicitly add an attribute release policy to support it.
