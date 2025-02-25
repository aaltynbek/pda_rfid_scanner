package com.pda_rfid_scanner;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.reactivex.subjects.PublishSubject;

import android.app.Activity;
import android.device.ScanDevice;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.math.BigInteger;
import java.io.IOException;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.pda_rfid_scanner.utils.LFUtil;

/** 
 * PdaRfidScannerPlugin - Improved version
 * 
 * Supports two scanning modes:
 * 1. Barcode scanning via ScanDevice
 * 2. RFID scanning via LFUtil
 */
public class PdaRfidScannerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private static final String TAG = "PdaRfidScannerPlugin";
  private static final String CHANNEL_NAME = "pda_rfid_scanner";
  private static final String EVENT_CHANNEL_NAME = "pda_rfid_scanner/stream";
  private static final String SCAN_ACTION = "scan.rcv.message";
  
  // Scanning modes
  private static final int MODE_BARCODE = 1;
  private static final int MODE_RFID = 2;
  
  private MethodChannel channel;
  private Activity activity;
  private Context context;
  protected static LFUtil lfUtil = null;
  private static PublishSubject<String> subject = PublishSubject.create();
  
  // Device state
  private ScanDevice scanDevice;
  private boolean isRfidPowerOn = false;
  private boolean isScannerOn = false;
  private int currentMode = 0;
  private boolean autoRestartScan = true;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    Log.d(TAG, "Plugin attached to engine");
    context = flutterPluginBinding.getApplicationContext();
    
    // Setup Method Channel
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);

    // Setup Event Channel for streaming scan results
    new EventChannel(flutterPluginBinding.getBinaryMessenger(), EVENT_CHANNEL_NAME)
        .setStreamHandler(new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object args, final EventChannel.EventSink events) {
            Log.d(TAG, "Event stream listener added");
            subject.subscribe(data -> events.success(data));
          }

          @Override
          public void onCancel(Object args) {
            Log.d(TAG, "Event stream listener canceled");
            // Can add cleanup if needed
          }
        });
  }

  /**
   * Broadcast receiver for barcode scanning
   */
  private BroadcastReceiver mScanReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      String action = intent.getAction();
      if (action.equals(SCAN_ACTION)) {
        byte[] barcode = intent.getByteArrayExtra("barocode");
        int barcodeLen = intent.getIntExtra("length", 0);
        
        if (barcode != null && barcodeLen > 0) {
          String barcodeStr = new String(barcode, 0, barcodeLen);
          Log.d(TAG, "Barcode scanned: " + barcodeStr);
          
          // Send the result to Flutter via Event Channel
          subject.onNext("barcode:" + barcodeStr);
          
          // Automatically restart scanner for next scan if enabled
          if (scanDevice != null) {
            scanDevice.stopScan();
            if (autoRestartScan) {
              scanDevice.startScan();
            }
          }
        }
      }
    }
  };

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    try {
      switch (call.method) {
        case "getPlatformVersion":
          result.success("Android " + android.os.Build.VERSION.RELEASE);
          break;
          
        case "setRfidPowerOn":
        case "setPowerOn": // Legacy support
          enableRfidModule(true, result);
          break;
          
        case "setRfidPowerOff":
        case "setPowerOff": // Legacy support
          enableRfidModule(false, result);
          break;
          
        case "startBarcodeScan":
        case "startScan": // Legacy support
          startBarcodeScan(result);
          break;
          
        case "stopBarcodeScan":
          stopBarcodeScan(result);
          break;
          
        case "setAutoRestartScan":
          boolean enable = call.argument("enable");
          autoRestartScan = enable;
          result.success("Auto restart " + (enable ? "enabled" : "disabled"));
          break;
          
        case "isScannerActive":
          result.success(isScannerOn);
          break;
          
        case "isRfidActive":
          result.success(isRfidPowerOn);
          break;
          
        case "getCurrentMode":
          String mode = "unknown";
          if (currentMode == MODE_BARCODE) mode = "barcode";
          else if (currentMode == MODE_RFID) mode = "rfid";
          result.success(mode);
          break;
          
        default:
          result.notImplemented();
          break;
      }
    } catch (Exception e) {
      Log.e(TAG, "Error in method call: " + e.getMessage());
      result.error("METHOD_ERROR", e.getMessage(), e.getStackTrace().toString());
    }
  }

  /**
   * Enable/disable RFID module
   */
  private void enableRfidModule(boolean enable, Result result) {
    if (enable) {
      if (isRfidPowerOn) {
        result.success("RFID already on");
        return;
      }
      
      // Turn off barcode scanner if active
      if (isScannerOn) {
        stopBarcodeScan(null);
      }
      
      // Enable RFID module
      if (lfUtil != null) {
        if (lfUtil.powerOn()) {
          try {
            lfUtil.open();
            isRfidPowerOn = true;
            currentMode = MODE_RFID;
            result.success("RFID on");
            Log.d(TAG, "RFID module powered on");
          } catch (Exception e) {
            Log.e(TAG, "Failed to open RFID module: " + e.getMessage());
            result.error("RFID_OPEN_ERROR", "Failed to open RFID module", e.getMessage());
          }
        } else {
          Log.e(TAG, "Failed to power on RFID module");
          result.error("RFID_POWER_ERROR", "Failed to power on RFID module", null);
        }
      } else {
        Log.e(TAG, "RFID util is not initialized");
        result.error("RFID_INIT_ERROR", "RFID util is not initialized", null);
      }
    } else {
      // Disable RFID module
      if (lfUtil != null) {
        try {
          lfUtil.close();
          lfUtil.powerOff();
          isRfidPowerOn = false;
          currentMode = 0;
          result.success("RFID off");
          Log.d(TAG, "RFID module powered off");
        } catch (IOException e) {
          Log.e(TAG, "Failed to close RFID module: " + e.getMessage());
          result.error("RFID_CLOSE_ERROR", "Failed to close RFID module", e.getMessage());
        }
      } else {
        Log.d(TAG, "RFID util is not initialized, nothing to turn off");
        result.success("RFID off");
      }
    }
  }

  /**
   * Start barcode scanning
   */
  private void startBarcodeScan(Result result) {
    if (isScannerOn) {
      if (result != null) result.success("Scanner already on");
      return;
    }
    
    // Turn off RFID if active
    if (isRfidPowerOn) {
      enableRfidModule(false, null);
    }
    
    try {
      Log.d(TAG, "Starting barcode scanner");
      
      // Initialize scanner if not yet initialized
      if (scanDevice == null) {
        scanDevice = new ScanDevice();
      }
      
      // Register receiver to get scan results
      IntentFilter filter = new IntentFilter();
      filter.addAction(SCAN_ACTION);
      activity.registerReceiver(mScanReceiver, filter);
      
      // Configure and start scanner
      scanDevice.setOutScanMode(0); // Output mode: broadcast
      scanDevice.openScan();
      scanDevice.startScan();
      
      isScannerOn = true;
      currentMode = MODE_BARCODE;
      
      if (result != null) result.success("Scanner started");
    } catch (Exception e) {
      Log.e(TAG, "Failed to start scanner: " + e.getMessage());
      if (result != null) result.error("SCANNER_ERROR", "Failed to start scanner", e.getMessage());
    }
  }

  /**
   * Stop barcode scanning
   */
  private void stopBarcodeScan(Result result) {
    if (!isScannerOn) {
      if (result != null) result.success("Scanner already off");
      return;
    }
    
    try {
      Log.d(TAG, "Stopping barcode scanner");
      
      // Unregister receiver
      try {
        activity.unregisterReceiver(mScanReceiver);
      } catch (Exception e) {
        Log.e(TAG, "Error unregistering receiver: " + e.getMessage());
      }
      
      // Stop and close scanner
      if (scanDevice != null) {
        scanDevice.stopScan();
        scanDevice.closeScan();
      }
      
      isScannerOn = false;
      currentMode = 0;
      
      if (result != null) result.success("Scanner stopped");
    } catch (Exception e) {
      Log.e(TAG, "Failed to stop scanner: " + e.getMessage());
      if (result != null) result.error("SCANNER_ERROR", "Failed to stop scanner", e.getMessage());
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    Log.d(TAG, "Plugin detached from engine");
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    Log.d(TAG, "Plugin attached to activity");
    activity = binding.getActivity();
    
    // Initialize LFUtil for RFID scanning
    lfUtil = new LFUtil(data -> 
      activity.runOnUiThread(() -> onRfidDataReceived(data))
    );
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    Log.d(TAG, "Plugin detached from activity for config changes");
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    Log.d(TAG, "Plugin reattached to activity for config changes");
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    Log.d(TAG, "Plugin detached from activity");
    
    // Clean up resources
    if (isScannerOn) {
      stopBarcodeScan(null);
    }
    
    if (isRfidPowerOn) {
      try {
        lfUtil.close();
        lfUtil.powerOff();
      } catch (Exception e) {
        Log.e(TAG, "Error closing RFID: " + e.getMessage());
      }
    }
    
    if (lfUtil != null) {
      lfUtil.dispose();
      lfUtil = null;
    }
    
    activity = null;
  }

  /**
   * Process RFID card data
   */
  protected static void onRfidDataReceived(final byte[] data) {
    try {
      String rfidData = processRfidData(data);
      if (rfidData != null && !rfidData.isEmpty()) {
        // Send the result to Flutter via Event Channel
        subject.onNext("rfid:" + rfidData);
      }
    } catch (Exception e) {
      Log.e(TAG, "Error processing RFID data: " + e.getMessage());
    }
  }

  /**
   * Process RFID data
   */
  private static String processRfidData(final byte[] data) {
    try {
      byte[] id = new byte[64];
      System.arraycopy(data, 0, id, 0, data.length);
      
      if ((data.length >= 20) & (id[19] == 35)) {
        // First RFID format
        byte[] temp = new byte[15];
        System.arraycopy(id, 2, temp, 0, 15);
        return new String(temp, "ascii");
      } else if (data.length >= 30) {
        // Second RFID format (FDX/HDX)
        int start = -1, end = -1;
        for (int i = 0; i < data.length; i++) {
          if (data[i] == 0x02) {
            start = i;
          } else if (data[i] == 0x03 || data[i] == 0x07) {
            end = i;
            break;
          }
        }
        
        if (start != -1 && end != -1) {
          byte[] tempBuffer = new byte[14];
          System.arraycopy(data, start + 1, tempBuffer, 0, tempBuffer.length);
          
          String rawString = new String(tempBuffer, "ascii");
          String idStr = new BigInteger(rev(rawString.substring(0, 10)), 16).toString(10);
          idStr = paddingLeft(idStr, 12, "0");
          String countCodeStr = new BigInteger(rev(rawString.substring(10, 13)), 16).toString(10);
          
          return countCodeStr + idStr;
        }
      }
    } catch (Exception e) {
      Log.e(TAG, "Error in processRfidData: " + e.getMessage());
    }
    
    return null;
  }

  /**
   * Helper function to reverse a string
   */
  private static String rev(String ox) {
    byte[] b = ox.getBytes();
    int j = 0;
    byte[] result = new byte[b.length];
    int i = b.length - 1;
    while (i >= 0) {
      result[j] = b[i];
      i--;
      j++;
    }
    return new String(result);
  }

  /**
   * Helper function to pad a string on the left
   */
  private static String paddingLeft(String rawString, int len, String fillChar) {
    StringBuilder stringBuilder = new StringBuilder();
    int fillLen = len - rawString.length();
    if (fillLen <= 0)
      return rawString;
    while (fillLen-- > 0) {
      stringBuilder.append(fillChar);
    }
    stringBuilder.append(rawString);
    return stringBuilder.toString();
  }

  /**
   * Static method for compatibility with older Flutter versions
   */
  public static void registerWith(Registrar registrar) {
    // Compatibility with old Flutter
  }
}