import threading
import uuid
from profilepoint.profilepoint import ProfilePoint

_thread_local = threading.local()

class ActivityProfilePoint(ProfilePoint):
    def __init__(self, name, thresholdSeconds):
        super().__init__(name)
        self.profile_points = {}
        self.id = uuid.uuid4()
        self.thresholdMSec = thresholdSeconds * 1000.0;
       
    def __exit__(self, exc_type, exc_value, traceback):
        super().__exit__(exc_type, exc_value, traceback)
        self.render()
         
    def register(self, functionName:str):
        if functionName not in self.profile_points:
            self.profile_points[functionName] = ActionProfilePoint(functionName)
        
        
        return self.profile_points[functionName]
    
    def render(self):
        activityTime = super().getWatch().elapsed_time()
        print(f"Threshold = {self.thresholdMSec}, Activity Time = {activityTime}")
        # if activityTime < self.thresholdMSec:
        #     return
        # if (activityTime < self.thresholdMSec):
            # print(f"Threshold = {self.thresholdMSec} is more than Activity Time = {activityTime}")
        #     return
        
        print("ProfilePoint, Id, Name, CallCount, TimeMSec, Percentage")
        
        print(f"ProfilePoint,{self.id},{self.name},1,{super().getWatch().elapsed_time():.0f},100")
        for profile_point_name in self.profile_points:
            pp = self.profile_points[profile_point_name]
            pp.render_in_context(self.id, super().getWatch().elapsed_time())
        
        # remove thread local variable
        if hasattr(_thread_local, 'pp'):
            del _thread_local.pp



class ActionProfilePoint(ProfilePoint):
    # def render(self):
        # do nothing
        # pass
        
    def render_in_context(self, id, totalTime):
        time = super().getWatch().elapsed_time()
        callCount = super().getWatch().run_count()
        print(f"ProfilePoint,{id},{self.name},{callCount},{time:.0f},{100.0*time/totalTime:.0f}")
        

# Simple profiling method
@staticmethod
def profile(name:str):
    # default threshold of 1 second
    return profile2(name, 1)
    
@staticmethod
def profile2(name:str, thresholdSeconds:int):
    if not hasattr(_thread_local, 'pp'):
        print(f"Profiling activity {name}")
        pp = ActivityProfilePoint(name, thresholdSeconds)
        _thread_local.pp = pp
        return _thread_local.pp
        
    return _thread_local.pp.register(name)
   
     