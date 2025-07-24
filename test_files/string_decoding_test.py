import base64

# Your encoded string
encoded = ".pi80.pkaG9tZXNfbWVzc2FnaW5nL25ld19tZXNzYWdl"

# Split the string by '.' and get the last part
base64_part = encoded.split('.')[-1]

# Decode from Base64
decoded_bytes = base64.b64decode(base64_part)
decoded_str = decoded_bytes.decode('utf-8')

print("Decoded string:", decoded_str)