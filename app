import os
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, ttk, Tk, Label, Button, DoubleVar
from PIL import Image, ImageDraw, ImageFont, ImageChops, ImageEnhance
import cv2
import numpy as np
from colour.io.luts import read_LUT
from scipy.interpolate import RegularGridInterpolator


class RGBHSVEditor:
    def __init__(self, master):
        self.frame = ttk.Frame(master, padding="10")
        self.frame.pack(fill='both', expand=True)

        ttk.Label(self.frame, text="Pilih Gambar / Folder:").grid(row=0, column=0, sticky='w')
        ttk.Button(self.frame, text="Pilih", command=self.select_input).grid(row=0, column=1, sticky='ew')

        ttk.Label(self.frame, text="Pilih Folder Output:").grid(row=1, column=0, sticky='w')
        ttk.Button(self.frame, text="Pilih", command=self.select_output).grid(row=1, column=1, sticky='ew')

        self.channels = ['R', 'G', 'B', 'H', 'S', 'V']
        self.values = {}
        self.labels = {}

        for idx, ch in enumerate(self.channels):
            self.values[ch] = tk.DoubleVar(value=1.0)
            self.labels[ch] = ttk.Label(self.frame, text=f"{ch}: 100%")
            self.labels[ch].grid(row=2 + idx, column=0, sticky='w')
            scale = ttk.Scale(self.frame, from_=0, to=2.0, orient='horizontal', variable=self.values[ch],
                              command=lambda v, c=ch: self.update_label(c))
            scale.grid(row=2 + idx, column=1, sticky='ew')

        self.start_button = ttk.Button(self.frame, text="Mulai Edit", command=self.start_processing, state='disabled')
        self.start_button.grid(row=9, columnspan=2, pady=10)

        self.status_label = ttk.Label(self.frame, foreground="blue", justify='center', anchor='center', wraplength=400)
        self.status_label.grid(row=8, column=0, columnspan=2, pady=(10, 0))
        
        self.input_paths = []
        self.output_folder = None

    def update_label(self, channel):
        val = self.values[channel].get()
        self.labels[channel].config(text=f"{channel}: {int(val * 100)}%")

    def select_input(self):
        paths = filedialog.askopenfilenames(title="Pilih Gambar", filetypes=[("Image Files", "*.jpg *.jpeg *.png *.bmp")])
        if not paths:
            folder = filedialog.askdirectory(title="Pilih Folder")
            if folder:
                self.input_paths = [os.path.join(folder, f) for f in os.listdir(folder) if f.lower().endswith(('jpg', 'jpeg', 'png', 'bmp'))]
        else:
            self.input_paths = list(paths)

        if self.input_paths and self.output_folder:
            self.start_button['state'] = 'normal'
        if self.input_paths:
            selected = self.input_paths[0]
            msg = f"[{len(self.input_paths)} Gambar Dipilih]" if len(self.input_paths) > 1 else f"[1 Gambar Dipilih]"
            msg += f"\n{selected}"
            self.status_label.config(text=msg)

    def select_output(self):
        self.output_folder = filedialog.askdirectory(title="Pilih Folder Output")
        if self.output_folder and self.input_paths:
            self.start_button['state'] = 'normal'
        if self.output_folder:
            msg = f"[1 Folder Dipilih]\n{self.output_folder}"
            self.status_label.config(text=msg)

    def start_processing(self):
        for path in self.input_paths:
            img = cv2.imread(path)
            if img is None:
                continue

            img = img.astype(np.float32) / 255.0
            b, g, r = cv2.split(img)
            r *= self.values['R'].get()
            g *= self.values['G'].get()
            b *= self.values['B'].get()
            rgb_img = cv2.merge([b, g, r])

            hsv_img = cv2.cvtColor(rgb_img, cv2.COLOR_BGR2HSV)
            h, s, v = cv2.split(hsv_img)
            h *= self.values['H'].get()
            s *= self.values['S'].get()
            v *= self.values['V'].get()
            hsv_img = cv2.merge([h.clip(0, 179), s.clip(0, 255), v.clip(0, 255)])

            final_img = cv2.cvtColor(hsv_img.astype(np.uint8), cv2.COLOR_HSV2BGR)

            out_name = Path(path).stem + "_edited.jpg"
            out_path = os.path.join(self.output_folder, out_name)
            cv2.imwrite(out_path, final_img)

        messagebox.showinfo("Selesai", "Semua gambar telah diproses.")


class MainApp:
    def __init__(self, root):
        self.root = root
        root.title("Multi Tool by @snap.snap.id")

        tab_control = ttk.Notebook(root)

        self.rgbhsv_frame = ttk.Frame(tab_control)
        RGBHSVEditor(self.rgbhsv_frame)
        tab_control.add(self.rgbhsv_frame, text='Edit RGB/HSV')

        self.lut_frame = ttk.Frame(tab_control)
        self.init_lut_tab()
        tab_control.add(self.lut_frame, text='Terapkan LUT')

        self.overlay_frame = ttk.Frame(tab_control)
        self.init_overlay_tab()
        tab_control.add(self.overlay_frame, text='Efek Overlay')

        self.pdf_frame = ttk.Frame(tab_control)
        self.init_pdf_tab()
        tab_control.add(self.pdf_frame, text='Gambar ke PDF')

        tab_control.pack(expand=1, fill='both')
    
    def init_overlay_tab(self):
        frame = ttk.Frame(self.overlay_frame, padding="10")
        frame.pack(fill='both', expand=True)

        self.overlay_photo_paths = []
        self.overlay_folder = None
        self.output_folder_overlay = None

        ttk.Label(frame, text="Pilih Foto:").grid(row=0, column=0)
        ttk.Button(frame, text="Pilih Foto", command=self.select_overlay_photos).grid(row=0, column=1)

        ttk.Label(frame, text="Pilih Folder Overlay:").grid(row=1, column=0)
        ttk.Button(frame, text="Pilih Folder", command=self.select_overlay_folder).grid(row=1, column=1)

        ttk.Label(frame, text="Pilih Folder Output:").grid(row=2, column=0)
        ttk.Button(frame, text="Pilih Folder", command=self.select_overlay_output_folder).grid(row=2, column=1)

        ttk.Label(frame, text="Opacity:").grid(row=3, column=0)
        self.overlay_opacity = tk.DoubleVar(value=0.5)
        self.overlay_opacity_label = ttk.Label(frame, text="50%")
        self.overlay_opacity_label.grid(row=3, column=2, sticky='w')

        opacity_scale = ttk.Scale(frame, from_=0.0, to=1.0, variable=self.overlay_opacity,
                                command=self.update_overlay_opacity_label)
        opacity_scale.grid(row=3, column=1, sticky='ew')

        self.overlay_status_label = ttk.Label(frame, text="", foreground="blue", justify='center', anchor='center')
        self.overlay_status_label.grid(row=4, columnspan=3)

        self.overlay_start_button = ttk.Button(frame, text="Mulai Proses Overlay", command=self.apply_overlay_batch, state='disabled')
        self.overlay_start_button.grid(row=5, columnspan=3, pady=(10, 5))

    def select_overlay_photos(self):
        paths = filedialog.askopenfilenames(filetypes=[("Image Files", "*.jpg *.jpeg *.png")])
        if paths:
            self.overlay_photo_paths = list(paths)
            msg = f"{len(paths)} foto dipilih."
            self.overlay_status_label.config(text=msg)
            self.update_overlay_button_state()

    def select_overlay_folder(self):
        path = filedialog.askdirectory()
        if path:
            self.overlay_folder = path
            msg = f"Folder overlay:\n{self.overlay_folder}"
            self.overlay_status_label.config(text=msg)
            self.update_overlay_button_state()

    def select_overlay_output_folder(self):
        path = filedialog.askdirectory()
        if path:
            self.output_folder_overlay = path
            msg = f"Folder output:\n{self.output_folder_overlay}"
            self.overlay_status_label.config(text=msg)
            self.update_overlay_button_state()

    def update_overlay_button_state(self):
        if self.overlay_photo_paths and self.overlay_folder and self.output_folder_overlay:
            self.overlay_start_button['state'] = 'normal'

    def update_overlay_opacity_label(self, value):
        val = int(float(value) * 100)
        self.overlay_opacity_label.config(text=f"{val}%")

    def blend_screen_with_opacity(self, image1, image2, opacity):
        overlay = Image.blend(Image.new("RGB", image1.size, (0, 0, 0)), image2, opacity)
        return ImageChops.screen(image1, overlay)

    def resize_overlay(self, overlay, base_size):
        return overlay.resize(base_size, Image.Resampling.LANCZOS)

    def apply_overlay_to_image(self, image_path, overlay_path, output_folder, opacity):
        try:
            img = Image.open(image_path).convert("RGB")
            overlay = Image.open(overlay_path).convert("RGB")
            overlay_resized = self.resize_overlay(overlay, img.size)
            blended = self.blend_screen_with_opacity(img, overlay_resized, opacity)

            base_name = Path(image_path).stem
            overlay_name = Path(overlay_path).stem
            filename = f"{base_name}_{overlay_name}.jpg"
            save_path = os.path.join(output_folder, filename)
            blended.save(save_path)
        except Exception as e:
            print(f"Error processing {image_path} with {overlay_path}: {e}")

    def apply_overlay_batch(self):
        if not self.overlay_photo_paths or not self.overlay_folder or not self.output_folder_overlay:
            self.overlay_status_label.config(text="Lengkapi semua input terlebih dahulu.")
            return

        overlay_files = [
            os.path.join(self.overlay_folder, f)
            for f in os.listdir(self.overlay_folder)
            if f.lower().endswith(('.jpg', '.jpeg', '.png'))
        ]
        if not overlay_files:
            self.overlay_status_label.config(text="Tidak ada file overlay ditemukan.")
            return

        opacity = self.overlay_opacity.get()
        for overlay_path in overlay_files:
            for photo_path in self.overlay_photo_paths:
                self.apply_overlay_to_image(photo_path, overlay_path, self.output_folder_overlay, opacity)

        self.overlay_status_label.config(text="Semua overlay telah diterapkan.")
        messagebox.showinfo("Selesai", "Proses overlay selesai.")

    
    def update_intensity_label(self, val):
        percentage = int(float(val) * 100)
        self.intensity_label.config(text=f"{percentage}%")

    # LUT tab methods
    def init_lut_tab(self):
        frame = ttk.Frame(self.lut_frame, padding="10")
        frame.pack(fill='both', expand=True)

        self.lut_image_paths = []
        self.lut_directory = None
        self.output_directory_lut = None

        ttk.Label(frame, text="Pilih Gambar:").grid(row=0, column=0)
        ttk.Button(frame, text="Pilih Gambar", command=self.select_lut_images).grid(row=0, column=1)

        ttk.Label(frame, text="Pilih Folder LUT (.cube):").grid(row=1, column=0)
        ttk.Button(frame, text="Pilih Folder", command=self.select_lut_folder).grid(row=1, column=1)

        ttk.Label(frame, text="Pilih Folder Output:").grid(row=2, column=0)
        ttk.Button(frame, text="Pilih Folder", command=self.select_lut_output_folder).grid(row=2, column=1)

        ttk.Label(frame, text="Format Output:").grid(row=3, column=0)
        self.format_var = tk.StringVar(value="png")
        ttk.Combobox(frame, textvariable=self.format_var, values=["png", "jpg", "bmp"]).grid(row=3, column=1)

        ttk.Label(frame, text="Intensitas LUT:").grid(row=4, column=0)

        self.intensity = tk.DoubleVar(value=1.0)
        self.intensity_label = ttk.Label(frame, text="100%")
        self.intensity_label.grid(row=4, column=2, sticky='w')

        intensity_scale = ttk.Scale(
            frame, from_=0.0, to=1.0, variable=self.intensity,
            command=self.update_intensity_label
        )
        intensity_scale.grid(row=4, column=1, sticky='ew')

        self.lut_status_label = ttk.Label(frame, text="", foreground='blue', justify='center', anchor='center')
        self.lut_status_label.grid(row=5, columnspan=2)

        self.lut_start_button = ttk.Button(frame, text="Mulai Penerapan LUT", command=self.apply_luts_to_images, state='disabled')
        self.lut_start_button.grid(row=6, columnspan=2, pady=(10, 5))

    def select_lut_images(self):
        paths = filedialog.askopenfilenames(filetypes=[("Image Files", "*.jpg *.png *.jpeg *.bmp")])
        if paths:
            self.lut_image_paths = list(paths)
            selected = self.lut_image_paths[0]
            msg = f"[{len(paths)} Gambar Dipilih]" if len(paths) > 1 else "[1 Gambar Dipilih]"
            msg += f"\n{selected}"
            self.lut_status_label.config(text=msg)
            self.update_lut_button_state()
    def select_lut_folder(self):
        path = filedialog.askdirectory()
        if path:
            self.lut_directory = path
            msg = f"[1 Folder LUT Dipilih]\n{self.lut_directory}"
            self.lut_status_label.config(text=msg)
            self.update_lut_button_state()

    def select_lut_output_folder(self):
        path = filedialog.askdirectory()
        if path:
            self.output_directory_lut = path
            msg = f"[1 Folder Output Dipilih]\n{self.output_directory_lut}"
            self.lut_status_label.config(text=msg)
            self.update_lut_button_state()

    def update_lut_button_state(self):
        if self.lut_image_paths and self.lut_directory and self.output_directory_lut:
            self.lut_start_button['state'] = 'normal'

    def apply_luts_to_images(self):
        self.lut_status_label.config(text="Proses dimulai...")
        self.root.update_idletasks()

        format_out = self.format_var.get()
        intensity = self.intensity.get()
        lut_files = [f for f in os.listdir(self.lut_directory) if f.endswith(".cube")]

        for img_path in self.lut_image_paths:
            img = cv2.imread(img_path)
            if img is None:
                continue
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB) / 255.0
            flat = img.reshape(-1, 3)

            for lut_file in lut_files:
                try:
                    lut = read_LUT(os.path.join(self.lut_directory, lut_file))
                    domain = np.linspace(0, 1, lut.table.shape[0])
                    interp = RegularGridInterpolator((domain, domain, domain), lut.table)
                    mapped = interp(flat.clip(0, 1)).reshape(img.shape)
                    blended = (img * (1 - intensity)) + (mapped * intensity)
                    out_img = (blended * 255).astype(np.uint8)
                    out_img = cv2.cvtColor(out_img, cv2.COLOR_RGB2BGR)

                    out_path = os.path.join(self.output_directory_lut, f"{Path(img_path).stem}_{Path(lut_file).stem}.{format_out}")
                    cv2.imwrite(out_path, out_img)
                except Exception as e:
                    print(f"Gagal menerapkan LUT {lut_file} ke {img_path}: {e}")

        messagebox.showinfo("Selesai", "Semua LUT telah diterapkan.")

    # PDF tab methods
    def init_pdf_tab(self):
        frame = ttk.Frame(self.pdf_frame, padding="10")
        frame.pack()

        self.source_folder = None
        self.output_folder_pdf = None

        ttk.Label(frame, text="Pilih Folder Sumber Gambar:").grid(row=0, column=0)
        ttk.Button(frame, text="Pilih Folder", command=self.select_pdf_source_folder).grid(row=0, column=1)

        ttk.Label(frame, text="Pilih Folder Output:").grid(row=1, column=0)
        ttk.Button(frame, text="Pilih Folder", command=self.select_pdf_output_folder).grid(row=1, column=1)

        self.pdf_start_button = ttk.Button(frame, text="Mulai Proses", command=self.convert_to_pdf, state='disabled')
        self.pdf_start_button.grid(row=2, columnspan=2, pady=(10, 5))

        self.pdf_status_label = ttk.Label(frame, text="", foreground='blue', justify='center', anchor='center')
        self.pdf_status_label.grid(row=3, columnspan=2)

    def select_pdf_source_folder(self):
        path = filedialog.askdirectory()
        if path:
            self.source_folder = path
            msg = f"[1 Folder Sumber Dipilih]\n{self.source_folder}"
            self.pdf_status_label.config(text=msg)
            self.update_pdf_button_state()

    def select_pdf_output_folder(self):
        path = filedialog.askdirectory()
        if path:
            self.output_folder_pdf = path
            msg = f"[1 Folder Output Dipilih]\n{self.output_folder_pdf}"
            self.pdf_status_label.config(text=msg)
            self.update_pdf_button_state()

    def update_pdf_button_state(self):
        if self.source_folder and self.output_folder_pdf:
            self.pdf_start_button['state'] = 'normal'

    def convert_to_pdf(self):
        try:
            paths = sorted([
                os.path.join(self.source_folder, f)
                for f in os.listdir(self.source_folder)
                if f.lower().endswith(('.jpg', '.jpeg', '.png'))
            ])
            images = []
            for p in paths:
                img = Image.open(p).convert("RGB")
                draw = ImageDraw.Draw(img)
                fname = Path(p).stem
                try:
                    font = ImageFont.truetype("arial.ttf", 64)
                except:
                    font = ImageFont.load_default()
                bbox = draw.textbbox((0, 0), fname, font=font)
                pos = (10, img.height - (bbox[3] - bbox[1]) - 10)
                draw.text((pos[0] + 2, pos[1] + 2), fname, font=font, fill="black")
                draw.text(pos, fname, font=font, fill="white")
                images.append(img)

            if images:
                pdf_path = os.path.join(self.output_folder_pdf, "output.pdf")
                images[0].save(pdf_path, save_all=True, append_images=images[1:])
                messagebox.showinfo("Selesai", f"PDF disimpan di:\n{pdf_path}")
        except Exception as e:
            messagebox.showerror("Error", str(e))

if __name__ == "__main__":
    root = tk.Tk()
    app = MainApp(root)
    root.mainloop()
