import argparse
import json
from sudo_matrix import Matrix

def process_json(file_path):
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            print("JSON data successfully loaded.")
            
            # Process the JSON data here
            puzzle = data.get("puzzle")
            if puzzle is None:
                print("Error: Key 'puzzle' not found in JSON data.")
            # else:
                # print(f"Puzzle data: {puzzle}")
            matrix = Matrix(puzzle)
            print("Matrix object successfully created.")
            print(f"Matrix isValid? {matrix.validate()}")
            print(f"Sudoku = {matrix}")
            # matrix.validate()
            if (matrix.solve()):
                print(f"Solved Sudoku = {matrix}")
                print(f"Solved after {matrix.solveCount} recursions!!")
            else:
                print(f"Unable to solve. Giving up after {matrix.solveCount} recursions!!!")
            
    except FileNotFoundError:
        print(f"Error: The file {file_path} was not found.")
    except json.JSONDecodeError:
        print("Error: Failed to decode JSON. Please check the file format.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a JSON file.")
    parser.add_argument("file_path", help="Path to the JSON file")
    args = parser.parse_args()
    
    process_json(args.file_path)