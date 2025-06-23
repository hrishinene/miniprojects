import time

class Stopwatch:
    def __init__(self):
        self.reset()

    def start(self):
        self.start_time = time.time()
        self.isRunning = True
        self.runCount += 1
        return self

    def stop(self):
        if self.isRunning:
            self.isRunning = False
            self.totalElapsedTime += (time.time() - self.start_time)

    def run_count(self):
        return self.runCount
    
    def is_running(self):
        return self.isRunning
    
    def elapsed_time(self):
        return 1000*(time.time() - self.start_time) if self.isRunning else 1000*self.totalElapsedTime
    
    def reset(self):
        self.start_time = None
        self.totalElapsedTime = 0
        self.isRunning = False
        self.runCount = 0
        