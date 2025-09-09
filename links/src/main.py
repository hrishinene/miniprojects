import importlib
import sys
from smart_scripts.input import read

# Read input and invoke script with given parameters

def main():
    print("Hello World")
    
    script_name = read("Script Name")
    function_name = read("Function Name")
    
    print(f"Invoking {function_name} from Script: {script_name}")
    
    # Invoke Script with argument of function
        
    # Dynamically import the script/module
    module = importlib.import_module(f"smart_scripts.{script_name}")
    # Get the function from the module
    main_func = getattr(module, "main")
    
    # Call the function 
    args = ["-f", function_name]
    sys.argv = [script_name] + ["-f", function_name]
    main_func()


if __name__ == '__main__':
        main()