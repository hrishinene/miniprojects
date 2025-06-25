#!/bin/bash
# Run the node application
cd ../../
npm run dev
if [ $? -eq 0 ]; then
    echo "Node application started successfully."
else
    echo "Failed to start the node application."
    exit 1
fi
# End of script