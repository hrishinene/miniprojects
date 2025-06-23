from profilepoint.stopwatch import Stopwatch

# Main RAII Class to profile code.
# Its subclasses Activity and Action are responsible to maintain the stack of Stopwatches
class ProfilePoint:
    def __init__(self, name):
        self.name = name
        self.stop_watch = Stopwatch()

    def __enter__(self):
        # print(f"[{self.name}] Start profiling...")
        self.start()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.stop()
        
        if exc_type:
            print(f"[{self.name}] Exception occurred: {exc_value}")
            
        return False  # Propagate exceptions if any
   
    def start(self):
        self.stop_watch.start()
        
    def stop(self):
        self.stop_watch.stop()
         
    def getWatch(self):
        return self.stop_watch
    