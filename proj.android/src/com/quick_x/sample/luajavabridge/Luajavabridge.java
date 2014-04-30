/****************************************************************************
Copyright (c) 2010-2012 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 ****************************************************************************/
package com.quick_x.sample.luajavabridge;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream; 
import java.io.FileNotFoundException;
import java.io.IOException;

import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.LinearLayout;
import android.widget.LinearLayout.LayoutParams;
import android.widget.Button;
import android.view.View; 
import android.view.View.OnClickListener; 
import android.widget.TextView;  
import android.view.Gravity;

public class Luajavabridge extends Cocos2dxActivity {
	static private Luajavabridge s_instance;
    static private LinearLayout m_webLayout;
    static private LinearLayout m_topLayout;
    static private WebView m_webView;
    static private Button m_backButton;
    static private TextView m_titleView ;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		s_instance = this;
        //web layout 
        m_webLayout = new LinearLayout(this);  
        LinearLayout.LayoutParams lytp = new LinearLayout.LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT);  
        s_instance.addContentView(m_webLayout, lytp); 

        m_webLayout.setOrientation(LinearLayout.VERTICAL);
	}

	static {
		System.loadLibrary("game");
	}

	static public void showAlertDialog(final String title,
			final String message, final int luaCallbackFunction) {
		s_instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				AlertDialog alertDialog = new AlertDialog.Builder(s_instance).create();
				alertDialog.setTitle(title);
				alertDialog.setMessage(message);
				alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						s_instance.runOnGLThread(new Runnable() {
							@Override
							public void run() {
								Cocos2dxLuaJavaBridge.callLuaFunctionWithString(luaCallbackFunction, "CLICKED");
								Cocos2dxLuaJavaBridge.releaseLuaFunction(luaCallbackFunction);
							}
						});
					}
				});
				alertDialog.setIcon(R.drawable.icon);
				alertDialog.show();
			}
		});
	}

	static public void showDialog(final String title,
			final String message, final String btn, final int luaCallbackFunction) {
		s_instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				AlertDialog alertDialog = new AlertDialog.Builder(s_instance).create();
				alertDialog.setTitle(title);
				alertDialog.setMessage(message);
				alertDialog.setButton(btn, new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						s_instance.runOnGLThread(new Runnable() {
							@Override
							public void run() {
								Cocos2dxLuaJavaBridge.callLuaFunctionWithString(luaCallbackFunction, "CLICKED");
								Cocos2dxLuaJavaBridge.releaseLuaFunction(luaCallbackFunction);
							}
						});
					}
				});
				alertDialog.setIcon(R.drawable.icon);
				alertDialog.show();
			}
		});
	}

    static public void displayWebView(final String url, final int x, final int y, final int width, final int height) {
//s_instance为成员变量，是当前的Activity。   m_webView是WebView类型的成员变量
        s_instance.runOnUiThread(new Runnable() {
            public void run() {
                m_webView = new WebView(s_instance);

                //初始化线性布局 里面加按钮和webView  
                m_topLayout = new LinearLayout(s_instance);        
                //m_topLayout.setOrientation(LinearLayout.VERTICAL);  

                //初始化返回按钮
                m_backButton = new Button(s_instance);
                m_backButton.setBackgroundResource(R.drawable.backbutton);
                m_backButton.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT));
                m_backButton.setText("X");
                //m_backButton.setTextColor(Color.argb(255, 255, 218, 154));
                m_backButton.setTextSize(25);                
                m_backButton.setOnClickListener(new OnClickListener() {                    
                    public void onClick(View v) {
                        removeWebView();
                    }
                });

                m_titleView = new TextView(s_instance);
                m_titleView.setGravity(Gravity.CENTER);
                m_titleView.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.FILL_PARENT));
                m_titleView.setText("hx2048 help");  
                m_titleView.setTextSize(25);
                m_titleView.setTextColor(0xff000000);
                m_titleView.setBackgroundColor(0xffede0c8);

                m_topLayout.addView(m_backButton);
                m_topLayout.addView(m_titleView);

                m_webLayout.addView(m_topLayout);
                m_webLayout.addView(m_webView); 

                LinearLayout.LayoutParams linearParams = (LinearLayout.LayoutParams) m_webView.getLayoutParams();
//可选的webview位置，x,y,width,height可任意填写，也可以做为函数参数传入。
                linearParams.leftMargin = x;
                linearParams.topMargin = y;
                linearParams.width = width;
                linearParams.height = height;
                m_webView.setLayoutParams(linearParams);

//可选的webview配置
                //m_webView.setBackgroundColor(0);
                m_webView.getSettings().setCacheMode(WebSettings.LOAD_NO_CACHE);
                m_webView.getSettings().setAppCacheEnabled(false);

                m_webView.setWebViewClient(new WebViewClient(){
                    @Override
                    public boolean shouldOverrideUrlLoading(WebView view, String url){
                            
                            return false;
                            
                    }
                });
                if (url.length()!=0) {
                    m_webView.loadUrl(url);
                }
            }
        });
    }

    static public void updateURL(final String url) {
//      Log.e("Vincent", "updateURL"+url);
        s_instance.runOnUiThread(new Runnable() {
            public void run() {
                m_webView.loadUrl(url);
            }
        });
    }
    
    static public void removeWebView() {
//      Log.e("Vincent", "removeWebView");
        s_instance.runOnUiThread(new Runnable() {
            public void run() {
                m_topLayout.removeView(m_backButton);
                m_backButton.destroyDrawingCache();

                m_topLayout.removeView(m_titleView);
                m_titleView.destroyDrawingCache();

                m_webLayout.removeView(m_topLayout);

                m_webLayout.removeView(m_webView); 
                m_webView.destroy();
            }
        });
    }

    static public void save(final String fname, final String s) {
        try {
            FileOutputStream outStream=s_instance.openFileOutput(fname,0);
            outStream.write(s.getBytes());
            outStream.close();
        } catch (FileNotFoundException e) {
            return;
        }
        catch (IOException e){
            return;
        }
    } 

    static public String load(final String fname)
    {
        try {
            FileInputStream inStream=s_instance.openFileInput(fname);
            ByteArrayOutputStream stream=new ByteArrayOutputStream();
            byte[] buffer=new byte[1024];
            int length=-1;
            while((length=inStream.read(buffer))!=-1)   {
                stream.write(buffer,0,length);
            }

            stream.close();
            inStream.close();
            String s = stream.toString();
            return s;
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e){
        }
        return "";
    } 
}
