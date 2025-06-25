# This script generates a model.ts, model.sql, modelController.ts, modelService.ts and modelRoute.ts file based on input given in the form of a json file

# Add documentation for the script in the form of docstrings.
# The json file should contain the model name and its attributes with their types.
# Example:
# {
#   "model_name": "User",
#   "attributes": {
#     "id": "number",
#     "username": "string",
#     "email": "string",
#     "password": "string",
#     "created_at": "date",
#     "updated_at": "date"
#   }
# }
# The script will generate the following files:
# - model.ts: TypeScript interface for the model
# - model.sql: SQL schema for the model
# - modelController.ts: Controller file for the model
# - modelService.ts: Service file for the model
# - modelRoute.ts: Route file for the model
# -*- coding: utf-8 -*-
# This file is part of the finsaas project.

import os
import json
import re
import sys
from typing import Dict, Any, List

def generate_model_files(model_name: str, model_data: Dict[str, Any]) -> None:
    """
    Generates model.ts, model.sql, modelController.ts, modelService.ts, and modelRoute.ts files based on the provided model data.
    
    :param model_name: Name of the model (e.g., 'User').
    :param model_data: Dictionary containing model attributes and their types.
    """
    # Generate TypeScript Model
    generate_model_ts(model_name, model_data)
    
    # Generate SQL Schema
    generate_model_sql(model_name, model_data)
    
    # Generate Controller
    generate_model_controller(model_name)
    
    # Generate Service
    generate_model_service(model_name)
    
    # Generate Route
    generate_model_route(model_name)

def generate_model_ts(model_name: str, model_data: Dict[str, Any]) -> None:
    """
    Generates a TypeScript model file.
    
    :param model_name: Name of the model.
    :param model_data: Dictionary containing model attributes and their types.
    """
    model_file_content = f"// Model for {model_name}\n\n"
    model_file_content += f"export interface {model_name} " + "{\n"
    
    for attr, attr_type in model_data.items():
        ts_type = convert_to_ts_type(attr_type)
        model_file_content += f"  {attr}: {ts_type};\n"
            
    model_file_content += "}\n" 
    
    model_file_content += f"\nexport const {model_name}Table = '{model_name.lower()}s';\n"
    
    with open(f"{model_name.lower()}.ts", "w") as model_file:
        model_file.write(model_file_content)
        
def convert_to_ts_type(attr_type: str) -> str:
    """
    Converts a given attribute type to TypeScript type.
    
    :param attr_type: Attribute type as a string.
    :return: Corresponding TypeScript type as a string.
    """
    type_mapping = {
        "string": "string",
        "number": "number",
        "boolean": "boolean",
        "date": "Date",
        "object": "Record<string, any>",
        "array": "any[]"
    }
    
    return type_mapping.get(attr_type, "any")

def generate_model_sql(model_name: str, model_data: Dict[str, Any]) -> None:
    """
    Generates a SQL schema file for the model.
    
    :param model_name: Name of the model.
    :param model_data: Dictionary containing model attributes and their types.
    """
    sql_file_content = f"-- SQL schema for {model_name}\n\n"
    sql_file_content += f"CREATE TABLE IF NOT EXISTS {model_name.lower()}s (\n"
    
    for attr, attr_type in model_data.items():
        sql_type = convert_to_sql_type(attr_type)
        sql_file_content += f"  {attr} {sql_type},\n"
        
    sql_file_content += "  PRIMARY KEY (id)\n);\n"
    
    with open(f"{model_name.lower()}.sql", "w") as sql_file:
        sql_file.write(sql_file_content)
def convert_to_sql_type(attr_type: str) -> str:
    """
    Converts a given attribute type to SQL type.
    
    :param attr_type: Attribute type as a string.
    :return: Corresponding SQL type as a string.
    """
    type_mapping = {
        "string": "VARCHAR(255)",
        "number": "INT",
        "boolean": "BOOLEAN",
        "date": "TIMESTAMP",
        "object": "JSONB",
        "array": "TEXT[]"
    }
    
    return type_mapping.get(attr_type, "TEXT")
def generate_model_controller(model_name: str) -> None:
    """
    Generates a controller file for the model.
    
    :param model_name: Name of the model.
    """
    controller_file_content = f"// Controller for {model_name}\n\n"
    controller_file_content += f"import {{ Request, Response }} from 'express';\n"
    controller_file_content += f"import * as {model_name}Service from './{model_name.lower()}Service';\n\n"
    
    controller_file_content += f"export const get{model_name}s = async (req: Request, res: Response) => {{\n"
    controller_file_content += f"  const {model_name.lower()}s = await {model_name}Service.getAll();\n"
    controller_file_content += "  res.json({ data: " + f"{model_name.lower()}s });\n"
    controller_file_content += "};\n\n"
    
    with open(f"{model_name.lower()}Controller.ts", "w") as controller_file:
        controller_file.write(controller_file_content)
def generate_model_service(model_name: str) -> None:
    """
    Generates a service file for the model.
    
    :param model_name: Name of the model.
    """
    service_file_content = f"// Service for {model_name}\n\n"
    service_file_content += f"import * as {model_name}Model from './{model_name.lower()}';\n\n"
    
    service_file_content += f"export const getAll = async () => {{\n"
    service_file_content += f"  // Logic to fetch all {model_name.lower()}s from the database\n"
    service_file_content += "  return [];\n"
    service_file_content += "};\n\n"
    
    with open(f"{model_name.lower()}Service.ts", "w") as service_file:
        service_file.write(service_file_content)
        
def generate_model_route(model_name: str) -> None:
    """Generates a route file for the model.

    :param model_name: Name of the model.
    """
    route_file_content = f"// Routes for {model_name}\n\n"
    route_file_content += f"import {{ Router }} from 'express';\n"
    route_file_content += f"import * as {model_name}Controller from './{model_name.lower()}Controller';\n\n"
    
    route_file_content += "const router = Router();\n\n"
    route_file_content += f"router.get('/{model_name.lower()}s', {model_name}Controller.get{model_name}s);\n\n"
    
    route_file_content += "export default router;\n"
    
    with open(f"{model_name.lower()}Route.ts", "w") as route_file:
        route_file.write(route_file_content)
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python model_gen.py <model_json_file>")
        sys.exit(1)
    
    model_json_file = sys.argv[1]
    