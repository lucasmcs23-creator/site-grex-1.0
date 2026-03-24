$code = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;

public class ImageProcessor {
    public static string Process(string inPath, string outPath) {
        using (Bitmap bmp = new Bitmap(inPath)) {
            int w = bmp.Width;
            int h = bmp.Height;

            int minX = w;
            int minY = h;
            int maxX = 0;
            int maxY = 0;

            BitmapData data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = data.Stride;
            IntPtr ptr = data.Scan0;
            int bytes = Math.Abs(stride) * h;
            byte[] rgbValues = new byte[bytes];
            System.Runtime.InteropServices.Marshal.Copy(ptr, rgbValues, 0, bytes);

            float bg_r = 5f, bg_g = 42f, bg_b = 77f;

            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    int idx = (y * stride) + (x * 4);
                    byte b = rgbValues[idx];
                    byte g = rgbValues[idx + 1];
                    byte r = rgbValues[idx + 2];
                    byte a = rgbValues[idx + 3];

                    float dr = r - bg_r;
                    float dg = g - bg_g;
                    float db = b - bg_b;
                    float dist = (float)Math.Sqrt(dr*dr + dg*dg + db*db);

                    if (dist < 40) {
                        rgbValues[idx + 3] = 0; // completely transparent
                    } else {
                        if (dist < 90) {
                            // blend
                            float alpha = (dist - 40) / 50f;
                            rgbValues[idx + 3] = (byte)(255 * alpha);
                        } 
                        
                        // It is part of the image content
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }

            System.Runtime.InteropServices.Marshal.Copy(rgbValues, 0, ptr, bytes);
            bmp.UnlockBits(data);
            
            if (maxX >= minX && maxY >= minY) {
                // Add a small padding of 2 pixels around
                minX = Math.Max(0, minX - 2);
                minY = Math.Max(0, minY - 2);
                maxX = Math.Min(w - 1, maxX + 2);
                maxY = Math.Min(h - 1, maxY + 2);
                
                Rectangle cropRect = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
                using (Bitmap cropped = bmp.Clone(cropRect, bmp.PixelFormat)) {
                    cropped.Save(outPath, ImageFormat.Png);
                    return "Saved " + outPath + " [" + cropRect.Width + "x" + cropRect.Height + "]";
                }
            }
            return "No content found";
        }
    }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
$res = [ImageProcessor]::Process("c:\Users\Lucas\Desktop\Curso Vibe Design\Site Garex\Imagens\Logo G.png", "c:\Users\Lucas\Desktop\Curso Vibe Design\Site Garex\Imagens\Logo_G_transparent.png")
Write-Output $res
