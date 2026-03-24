$code = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;

public class ImageProcessor3 {
    public static string Process(string inPath, string outPath) {
        using (Bitmap bmp = new Bitmap(inPath)) {
            int w = bmp.Width;
            int h = bmp.Height;

            int minX = w, minY = h, maxX = 0, maxY = 0;

            BitmapData data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = data.Stride;
            IntPtr ptr = data.Scan0;
            int bytes = Math.Abs(stride) * h;
            byte[] rgbValues = new byte[bytes];
            System.Runtime.InteropServices.Marshal.Copy(ptr, rgbValues, 0, bytes);

            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    int idx = (y * stride) + (x * 4);
                    byte b = rgbValues[idx];
                    byte g = rgbValues[idx + 1];
                    byte r = rgbValues[idx + 2];
                    
                    // We want to keep only the pure 'G' which is bright (gold/white).
                    // The blue background has low R (around 5), moderate G (42), high B (77).
                    // Any pixel with R < 70 is definitely background or dark shadow. 
                    
                    if (r < 75 && g < 75) {
                        rgbValues[idx + 3] = 0; // Transparent
                    } else {
                        // For transition pixels to avoid blue halo
                        // Limit blue channel so it doesn't look blue
                        byte max_b = (byte)(Math.Min(g, r));
                        if (b > max_b) {
                            rgbValues[idx] = max_b; 
                        }
                        
                        if (r < 140) {
                            // Blend alpha based on how bright red is
                            float alpha = (r - 75) / 65f;
                            if (alpha < 0) alpha = 0;
                            if (alpha > 1) alpha = 1;
                            rgbValues[idx + 3] = (byte)(255 * alpha);
                        } else {
                            rgbValues[idx + 3] = 255; // Fully opaque
                        }
                        
                        // Update bounding box if heavily visible
                        if (rgbValues[idx + 3] > 10) {
                            if (x < minX) minX = x;
                            if (x > maxX) maxX = x;
                            if (y < minY) minY = y;
                            if (y > maxY) maxY = y;
                        }
                    }
                }
            }

            System.Runtime.InteropServices.Marshal.Copy(rgbValues, 0, ptr, bytes);
            bmp.UnlockBits(data);
            
            if (maxX >= minX && maxY >= minY) {
                minX = Math.Max(0, minX - 2);
                minY = Math.Max(0, minY - 2);
                maxX = Math.Min(w - 1, maxX + 2);
                maxY = Math.Min(h - 1, maxY + 2);
                
                Rectangle cropRect = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
                using (Bitmap cropped = bmp.Clone(cropRect, bmp.PixelFormat)) {
                    cropped.Save(outPath, ImageFormat.Png);
                    return "Saved pure G to " + outPath + " [" + cropRect.Width + "x" + cropRect.Height + "]";
                }
            }
            return "No content found";
        }
    }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
$res = [ImageProcessor3]::Process("c:\Users\Lucas\Desktop\Curso Vibe Design\Site Garex\Imagens\Logo G.png", "c:\Users\Lucas\Desktop\Curso Vibe Design\Site Garex\Imagens\Logo_G_transparent.png")
Write-Output $res
