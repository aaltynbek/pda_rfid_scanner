package com.pda_rfid_scanner.utils;

import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidParameterException;

import android_serialport_api.SerialPort;
import android_serialport_api.SerialPortTool;

/**
 * 低频卡模块操作帮助类
 */
public class LFUtil {
    private static final String PATH = "/dev/ttyS3";
    private static final int BAUTRATE = 9600;

    private final static Object lockObj = new Object();
    protected SerialPortTool serialPortTool;
    protected SerialPort mSerialPort;
    private InputStream mInputStream;
    private ReadThread mReadThread;
    private IDataReceive iDataReceive;
    private boolean mIsOpen = false;
    private boolean mIsRunning = false;

    private class ReadThread extends Thread {

        @Override
        public void run() {
            super.run();
            while (mIsRunning) {
                int size = 0;
                try {
                    // Log.e("ReadThread", "开始读串口数据..." + (mInputStream == null ?
                    // "mInputStream=null" : ""));
                    if (mInputStream != null && mInputStream.available() > 0) {
                        byte[] buffer = new byte[64];
                        size = mInputStream.read(buffer, 0, buffer.length);
                        // Log.e("ReadThread", "读串口数据 len=" + size);
                        if (size > 0) {
                            if (iDataReceive != null) {
                                byte[] data = new byte[size];
                                System.arraycopy(buffer, 0, data, 0, size);
                                Log.e("ReadThread STRING IS", ByteUtils.bytesToHexString(data));
                                iDataReceive.onLFDataReceived(data);
                            }
                        }
                    }
                    Thread.sleep(20);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            // Log.e("ReadThread", "线程退出!!!");
        }
    }

    /**
     * 1.创建低频帮助对象
     *
     * @param iDataReceive 数据回调方法
     */
    public LFUtil(IDataReceive iDataReceive) {

        if (mSerialPort == null) {
            serialPortTool = new SerialPortTool();
            /* Create a receiving thread */
            if (mReadThread == null) {
                mIsRunning = true;
                mReadThread = new ReadThread();
                mReadThread.start();
            }
        }
        this.iDataReceive = iDataReceive;
    }

    /**
     * 2.模块上电
     *
     * @return
     */
    public boolean powerOn() {
        return PowerUtil.power("1");
    }

    /**
     * 3.模块下电
     *
     * @return
     */
    public boolean powerOff() {
        return PowerUtil.power("0");
    }

    /**
     * 4.打开模块
     *
     * @return true 开启成功， false 开启模块串口失败
     * @throws SecurityException
     * @throws InvalidParameterException
     */
    public synchronized boolean open() throws Exception {
        boolean bRet = false;

        if (serialPortTool == null) {
            synchronized (lockObj) {
                if (serialPortTool == null)
                    serialPortTool = new SerialPortTool();
            }
        }
        if (!mIsOpen) {
            mSerialPort = serialPortTool.getSerialPort(PATH, BAUTRATE);
            mInputStream = mSerialPort.getInputStream();
            bRet = mIsOpen = true;
        }
        return bRet;
    }

    /**
     * 5.关闭模块
     */
    public synchronized void close() throws IOException {
        if (mInputStream != null) {// 关闭输出流
            mInputStream.close();
            mInputStream = null;
        }
        if (serialPortTool != null) {
            serialPortTool.closeSerialPort();
        }
        mIsOpen = false;
    }

    /**
     * 6.关闭模块&释放资源
     */
    public void dispose() {
        if (mReadThread != null) {
            mIsRunning = false;
            mReadThread.interrupt();
            mReadThread = null;
        }
        if (mIsOpen && serialPortTool != null) {
            serialPortTool.closeSerialPort();
        }
        serialPortTool = null;
    }

    /**
     * 是否已开启
     *
     * @return
     */
    public boolean isOpened() {
        return mIsOpen;
    }
}
