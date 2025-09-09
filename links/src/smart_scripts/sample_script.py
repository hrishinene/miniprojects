import sys
import argparse

from smart_scripts.input import read, read_int, read_date

#===============================================================================
# Smart Functions section
#===============================================================================
def hello(name=None):
        if name is None:
                name = input("Enter name: ")
                
        print(f"Hello {name}!")

def goodbye(dt):
        print(f"[{dt}]Goodbye!")

#===============================================================================
# Following is boilerplate code for SmartScript
#===============================================================================
def printUsage():
        print("\n=====================================\n")
        print("Script generated on Tue Jul 15 11:56:49 2025")
        print("This script does CHANGEME. It has public functions so that they can be invoked from outside.")
        print("Usage sampleSmartScript.py -f <Function Name>")
        print("\n=====================================\n")
#===============================================================================

def main():
        parser = argparse.ArgumentParser(
                description="This script does CHANGEME. It has public functions so that they can be invoked from outside."
        )

        try:
                print(f"Parsing arguments: {sys.argv}")

                parser.add_argument(
                        '-f', '--function', type=str, required=True, help='Name of function'
                )
                args = parser.parse_args()

                func_map = {
                        'hello': lambda: hello(read("name")),
                        'goodbye': lambda: goodbye(read_date("dt"))
                }

                if args.function in func_map:
                        func_map[args.function]()
                else:
                        print(f"Unknown function: {args.function}\nAvailable functions are: {', '.join(func_map.keys())}")

        except Exception as e:
                print(f"Error: {e}")
                printUsage()
                sys.exit(1)

if __name__ == '__main__':
        main()