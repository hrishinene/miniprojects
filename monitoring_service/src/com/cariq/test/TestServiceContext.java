package com.cariq.test;

import java.util.Hashtable;
import java.util.Map;

/**
 * Context to hold configurable values for runtime
 * @author HVN
 *
 */
public class TestServiceContext {
	static Map<String, Object> map = new Hashtable<String, Object>();
	
	public static Object put(String key, Object value) {
		return map.put(key, value);
	}
	
	public static Object get(String key) {
		return map.get(key);
	}

}
