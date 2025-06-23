from profilepoint.stopwatch import Stopwatch

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
        
        # self.render()
        # print(f"Exiting profilepoint: {self}")
        
        # print(f"[{self.name}] End profiling. Elapsed time: {self.stop_watch.elapsed_time():.4f} seconds")
        
        if exc_type:
            print(f"[{self.name}] Exception occurred: {exc_value}")
            
        return False  # Propagate exceptions if any
   
    def start(self):
        self.stop_watch.start()
        
    def stop(self):
        self.stop_watch.stop()
         
    def getWatch(self):
        return self.stop_watch
    
    # # def render(self):
    #     raise NotImplementedError("Subclasses must implement the render method")
        