#===============================================================================
# AUTHORIZATION CODE GRANT WITH PKCE AND CLIENT SECRET
#===============================================================================

## Set constants ##
AUTH_DOMAIN="MYDOMAIN.auth.REGION.amazoncognito.com" # Update MYDOMAIN and REGION
CLIENT_ID="xxxxxxxxxxxxxxxxxxxxxxxxx" # Replace with app client ID
CLIENT_SECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Replace with app client secret
RESPONSE_TYPE="code"
REDIRECT_URI="https://example.com/" # Replace with configured redirect URI
SCOPE="openid"

USERNAME="testuser" # Replace with valid user
PASSWORD="password "# Replace with valid password

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

## 4. Get auth code from "code" query paramater and get full redirect from ##
##    "Location" header                                                    ##
curl_redirect="$(printf "%s" "$curl_response" \
                    | awk '/^< location: / {
                        gsub(/\r/, "");
                        print $3;
                    }'
                )"
auth_code="$(printf "%s" "$curl_redirect" \
                | awk '{
                    sub(/.*code=/, "");
                    print
                }')"

## 5. Exchange auth code with tokens by hitting /oauth2/token endpoint ##
authorization="$(printf "${CLIENT_ID}:${CLIENT_SECRET}" \
                    | base64 \
                    | tr -d "\n"
                )"
GRANT_TYPE="authorization_code"
curl "https://${AUTH_DOMAIN}/oauth2/token" \
    -H "Authorization: Basic ${authorization}" \
    -d "grant_type=${GRANT_TYPE}" \
    -d "client_id=${CLIENT_ID}" \
    -d "code=${auth_code}" \
    -d "redirect_uri=${REDIRECT_URI}" 
    
