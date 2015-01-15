package com.cariq.test;

public class ServiceTestProg {
	public static class Writer {
		public void write(String message) {
			System.out.println("[ServiceMonitorTest] : " + message);
		}
	}
	
	enum ServiceResponse {
		AWAITED,
		SUCCESS,
		TIMEEDOUT
	}
	
	ServiceResponse response = ServiceResponse.AWAITED;
	
	// To write log uniformly
	Writer writer = new Writer();

	private void run() throws InterruptedException {
		// Create a monitor service and keep looping till a response is received
		TestService monitoredService = new MonitoredService(new TestServiceCallback() {
			
			@Override
			public void onTimeout() {
				response = ServiceResponse.TIMEEDOUT;
			}
			
			@Override
			public void onSuccess() {
				response = ServiceResponse.SUCCESS;
			}
		});
		
		// Call the method on monitoredService instead of AndroidService.
		// monitoredService invokes Androidservice
		monitoredService.testMethod();
		
		// Keep waiting for the method to finish, or timeout
		while (response == ServiceResponse.AWAITED) {
			Thread.sleep(1000);
			writer.write("Waiting for service callback...");
		}
		
		if (response == ServiceResponse.TIMEEDOUT) {
			writer.write("Request timed out... no callback received... exiting!!");
			System.exit(1);
		}
		else
			writer.write("Success!! Callback received!!");
	}
	/**
	 * Invoke with timeout time and time required form method.
	 * @param args
	 */
	public static void main(String[] args) {
		if (args.length != 2) {
			printUsage();
			return;
		}
		int responseTimeSeconds = Integer.parseInt(args[0]);
		int timeoutSeconds = Integer.parseInt(args[1]);

		if (timeoutSeconds < 1 || timeoutSeconds > 1000
				|| responseTimeSeconds < 1 || responseTimeSeconds > 1000)
			printUsage();
		
		TestServiceContext.put("TIMEOUT", timeoutSeconds * 1000);
		TestServiceContext.put("RESPONSE_TIME", responseTimeSeconds * 1000);
		System.out.println("TIMEOUT = " + timeoutSeconds + ", SERVICE RESPONSE TIME:" + responseTimeSeconds);

		ServiceTestProg svc = new ServiceTestProg();
		try {
			svc.run();
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	private static void printUsage() {
		System.out.println("java com.cariq.test.TestService <service response time seconds> <timeout seconds>");
		System.out.println("Timeout should be between 1 and 100");
		System.out.println("Service response time should be between 1 and 100");

	}

}
