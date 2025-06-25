# This script generates snippets to be added into the modelroute.ts file containing route as well as swagger documentation along with code snippet in modelController.ts and modelService.ts
# The script takes the model name and API name along with the HTTP method as input.
# It generates the necessary code snippets for the model route, controller, and service files.
# The generated code includes Swagger documentation for the API endpoint.
# The script is designed to be run from the command line with the model name and API name as arguments.

import sys
import json
import os
def generate_api_snippet(model_name: str, api_name: str, http_method: str) -> None:
    """
    Generates code snippets for the model route, controller, and service files based on the provided model name, API name, and HTTP method.
    
    :param model_name: Name of the model (e.g., 'User').
    :param api_name: Name of the API endpoint (e.g., 'getUser').
    :param http_method: HTTP method for the API endpoint (e.g., 'GET', 'POST').
    """
    # Generate route snippet including Swagger documentation
    route_snippet = f"""
// {api_name} route for {model_name}
import express from 'express';
import {{ {api_name} }} from './{model_name}Controller';

const router = express.Router();

/**
 * @swagger
 * /{model_name.lower()}/{api_name.lower()}:
 *   {http_method.lower()}:
 *     summary: {api_name} for {model_name}
    *     description: Endpoint to {api_name} for {model_name}.
    *     responses:
    *       200:
    *         description: Successful response.
    *       500:
    *         description: Internal server error.
 */
router.{http_method.lower()}('/{api_name.lower()}', {api_name});

export default router;
"""

    # Ensure the model name is in PascalCase for the controller and service
    model_name = model_name[0].upper() + model_name[1:]
    
    # Generate controller snippet
    controller_snippet = f"""
// {api_name} controller for {model_name}
export const {api_name} = async (req, res) => {{
    try {{
        const result = await {model_name}Service.{api_name}(req.params);
        res.status(200).json(result);
    }} catch (error) {{
        res.status(500).json({{ message: error.message }});
    }}
}};
"""
    
    # Generate service snippet
    service_snippet = f"""
// {api_name} service for {model_name}
export const {api_name} = async (params) => {{
    // Implement the logic for {api_name} here
    // For example, fetching data from the database
    return await database.query('SELECT * FROM {model_name.lower()} WHERE id = $1', [params.id]);
}};
"""
    
    # Print the generated snippets
    print("Route Snippet:")
    print(route_snippet)
    
    print("Controller Snippet:")
    print(controller_snippet)
    
    print("Service Snippet:")
    print(service_snippet)
    
if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python api_gen.py <model_name> <api_name> <http_method>")
        sys.exit(1)
    
    model_name = sys.argv[1]
    api_name = sys.argv[2]
    http_method = sys.argv[3].upper()
    