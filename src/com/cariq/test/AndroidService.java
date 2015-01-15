package com.cariq.test;

public class AndroidService {

	TestServiceCallback callback;

	/**
	 * @param callback
	 * @param responseTime
	 */
	public AndroidService(TestServiceCallback callback) {
		this.callback = callback;
	}

	static class ServiceThread implements Runnable {
		TestServiceCallback callback;

		/**
		 * @param responseTime
		 * @param callback
		 */
		public ServiceThread(TestServiceCallback callback) {
			this.callback = callback;
		}

		@Override
		public void run() {
			try {
				System.out.println("[AndroidService]: Start Executing Method...");
				Thread.sleep((int) TestServiceContext.get("RESPONSE_TIME")); // doing work...
				System.out
						.println("[AndroidService] : Completed Executing Method!!");

			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			// invoke the callback
			callback.onSuccess();
		}

	}

	public void serviceMethod() {
		// start a thread that will call callback after responseTime - but return
		// control back immediately
		Thread t = new Thread(new ServiceThread(callback));
		t.start();
	}
}
