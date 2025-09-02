# Create a shell script that takes 1 argument, the model name, 
# and copies a set of files from existing source tree by renaming them
# It also changes names in the files to match the model name
#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <model_name>"
    exit 1
fi

# if model name is not lower case or contains spaces, exit with error
if [[ ! "$1" =~ ^[a-z]+$ ]]; then
    echo "Error: Model name must be lowercase and contain no spaces."
    exit 1
fi

MODEL_NAME=$1
# Create a model name with the first letter capitalized
MODEL_NAME_CAPITALIZED=$(echo "$MODEL_NAME" | sed 's/^\(.\)/\U\1/')

# define paths to the source files
MODEL_FILE="src/models/user.ts"
ROUTE_FILE="src/routes/userRoutes.ts"
CONTROLLER_FILE="src/controllers/userController.ts"
SERVICE_FILE="src/services/userService.ts"
SCHEMA_FILE="src/schema/models/users.sql"

# define the new file names
NEW_MODEL_FILE="src/models/${MODEL_NAME}.ts"
NEW_ROUTE_FILE="src/routes/${MODEL_NAME}Routes.ts"
NEW_CONTROLLER_FILE="src/controllers/${MODEL_NAME}Controller.ts"
NEW_SERVICE_FILE="src/services/${MODEL_NAME}Service.ts"
NEW_SCHEMA_FILE="src/schema/models/${MODEL_NAME}s.sql"

# copy and rename the files
cp "$MODEL_FILE" "$NEW_MODEL_FILE"
cp "$ROUTE_FILE" "$NEW_ROUTE_FILE"
cp "$CONTROLLER_FILE" "$NEW_CONTROLLER_FILE"
cp "$SERVICE_FILE" "$NEW_SERVICE_FILE"
cp "$SCHEMA_FILE" "$NEW_SCHEMA_FILE"

# replace occurrences of 'User' with the model name in the new files
sed -i "s/User/${MODEL_NAME_CAPITALIZED}/g" "$NEW_MODEL_FILE"
sed -i "s/User/${MODEL_NAME_CAPITALIZED}/g" "$NEW_ROUTE_FILE"
sed -i "s/User/${MODEL_NAME_CAPITALIZED}/g" "$NEW_CONTROLLER_FILE"
sed -i "s/User/${MODEL_NAME_CAPITALIZED}/g" "$NEW_SERVICE_FILE"
sed -i "s/User/${MODEL_NAME_CAPITALIZED}/g" "$NEW_SCHEMA_FILE"

# replace occurrences of 'user' with the model name in the new files
sed -i "s/user/${MODEL_NAME}/g" "$NEW_MODEL_FILE"
sed -i "s/user/${MODEL_NAME}/g" "$NEW_ROUTE_FILE"
sed -i "s/user/${MODEL_NAME}/g" "$NEW_CONTROLLER_FILE"
sed -i "s/user/${MODEL_NAME}/g" "$NEW_SERVICE_FILE"
sed -i "s/user/${MODEL_NAME}/g" "$NEW_SCHEMA_FILE"