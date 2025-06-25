-- Create Database finsaas and run the schema initialization script from src/schema/schema.sql
CREATE DATABASE finsaas;
\c finsaas;
\i src/schema/schema.sql;
