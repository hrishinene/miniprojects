import argparse
import json
from time import sleep
from profilepoint.activity import profile
from profilepoint.profilepoint import ProfilePoint

def process_transactions(keyword_file, training_verification_file):
    # Add your processing logic here
    print(f"Processing {keyword_file} and {training_verification_file}")
    sleep(4)
    
if __name__ == "__main__":
    with profile("main"):
        parser = argparse.ArgumentParser(description="Process a JSON file.")
        parser.add_argument("keyword_file", help="Keywords.xlsx file")
        parser.add_argument("training_verification_file", help="transactions.xlsx file")
        args = parser.parse_args()
    
        process_transactions(args.keyword_file, args.training_verification_file)