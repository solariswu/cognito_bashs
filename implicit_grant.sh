#!/usr/bin/env bash

#===============================================================================
# IMPLICIT CODE GRANT
#===============================================================================

## Set constants ##
AUTH_DOMAIN="MYDOMAIN.auth.REGION.amazoncognito.com" # Update MYDOMAIN and REGION
CLIENT_ID="xxxxxxxxxxxxxxxxxxxxxxxxx" # Replace with app client ID
RESPONSE_TYPE="code"
REDIRECT_URI="https://example.com/" # Replace with configured redirect URI
SCOPE="openid"

USERNAME="testuser" # Replace with valid user
PASSWORD="password" # Replace with valid password

## 1. Make request to /oauth2/authorize endpoint ##
curl_response="$(
    curl -sv "https://${AUTH_DOMAIN}/oauth2/authorize?response_type=${RESPONSE_TYPE}&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SCOPE}" 2>&1
)"

## 2. Get CSRF token and login redirect URL from response Location and Cookie ##
##    headers, respectively                                                   ##
curl_redirect="$(printf "%s" "$curl_response" \
                    | awk '/^< location: / {
                        gsub(/\r/, "");
                        print $3;
                    }')"
csrf_token="$(printf "%s" "$curl_response" \
                   | awk '/^< set-cookie: XSRF-TOKEN/ {
                       gsub(/^XSRF-TOKEN=|;$/, "", $3);
                       print $3;
                    }')"

## 3. Authenticate with User Pool by posting credentials to /login endpoint ##
curl_response="$(
    curl -sv "$curl_redirect" \
        -H "Cookie: XSRF-TOKEN=${csrf_token}; Path=/; Secure; HttpOnly" \
        -d "_csrf=${csrf_token}" \
        -d "username=${USERNAME}" \
        -d "password=${PASSWORD}" 2>&1
)"
curl_redirect="$(printf "%s" "$curl_response" \
                    | awk '/^< location: / {
                        gsub(/\r/, "");
                        print $3;
                    }')"

## 4. Print received User Pool tokens ##
printf "%s" "$curl_redirect" \
    | awk '{
        split($0, url, "#");
        redirect_url = url[1];
        print "redirect_uri=" redirect_url;

        query_params_count = split(url[2], query_params, "&");
        for (idx = 1; idx <= query_params_count; idx++) {
            print query_params[idx];
        }
    }'
