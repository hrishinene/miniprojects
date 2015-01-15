package com.cariq.test;

/**
 * Call forwarder. Calls service method and waits for callback till specific
 * time Waiting for timeout is achieved by lock.wait(timeout) method
 * 
 * @author HVN
 *
 */
public class MonitoredService implements TestService {
	TestServiceCallback callback = null;
	AndroidService service;
	Object lock = new Object();

	/**
	 * @param callback
	 */
	public MonitoredService(TestServiceCallback callback) {
		this.callback = callback;
		service = new AndroidService(new TestServiceCallback() {

			@Override
			public void onTimeout() {
				// This is not going to get called...
				throw new UnsupportedOperationException(
						"MonitoringService OnTimeout not implemented!!");
			}

			@Override
			public void onSuccess() {
				synchronized (lock) {
					lock.notify();
				}
			}
		});
	}

	/**
	 * Inner class - a thread to wait for the callback or timeout if not
	 * callback received
	 * 
	 * @author HVN
	 *
	 */
	class MonitoringThread implements Runnable {
		@Override
		public void run() {
			int timeout = (int) TestServiceContext.get("TIMEOUT");
			try {
				synchronized (lock) {
					long beforeTime = System.currentTimeMillis();
					lock.wait(timeout);
					long afterTime = System.currentTimeMillis();

					// Wait is over due to timeout, or notify?
					if (afterTime - beforeTime >= (timeout - 10))
						callback.onTimeout(); // timeout case
					else
						callback.onSuccess(); // notify case
				}
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}

	}

	/**
	 * The call forwarding method... calls method and starts monitoring...
	 */
	public void testMethod() {
		// start a thread that will call back after responseTime - but return
		// control back immediately
		service.serviceMethod();
		
		// start monitoring thread to wait for TIMEOUT
		Thread t = new Thread(new MonitoringThread());
		t.start();
	}
}
