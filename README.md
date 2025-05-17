# 📸 Multi Tool Image Processor by @snap.snap.id

A multi-functional desktop image processing application built with Python and Tkinter. This tool offers a convenient graphical interface for applying RGB/HSV adjustments, LUT filters, overlay effects, and converting images to PDF. Designed for photographers, creative businesses, and photo booth services.

---

## ✨ Features

* **RGB/HSV Editor**: Adjust the Red, Green, Blue, Hue, Saturation, and Value levels of one or multiple images.
* **LUT Application**: Batch-apply `.cube` LUT files to images with customizable intensity and output format.
* **Overlay Effect**: Batch overlay images (e.g. frames, logos) onto photos with adjustable opacity.
* **Image to PDF**: Convert multiple images into PDF documents (feature to be added).

---

## 📦 Requirements

* Python 3.9+
* Dependencies:

  ```bash
  pip install pillow opencv-python numpy colour-science scipy
  ```

---

## 📂 Project Structure

```
.
├── multi_tool_app.py       # Main Python application file
├── /overlays/              # Example folder for overlay images
├── /luts/                  # Example folder for .cube LUT files
└── README.md               # Project documentation
```

---

## 🚀 How to Run

1. Install Python and required libraries.
2. Run the application:

   ```bash
   python multi_tool_app.py
   ```
3. Use the tabbed interface to access different tools.

---

## 🖥️ Application Tabs Overview

### 📊 Edit RGB/HSV

* **Select Image/Folder**: Choose one or multiple images.
* **Select Output Folder**: Where processed images will be saved.
* **Adjust Sliders**: Set percentage adjustments for R, G, B, H, S, V.
* **Start Editing**: Applies adjustments and saves images.

---

### 🎨 Apply LUT

* **Select Images**: Choose target images.
* **Select LUT Folder**: Folder containing `.cube` LUT files.
* **Select Output Folder**: Destination for processed images.
* **Select Output Format**: Choose between `png`, `jpg`, or `bmp`.
* **Adjust Intensity**: Control blend between original and LUT-processed image.
* **Apply LUTs**: Batch-apply all LUTs to selected images.

---

### 🖼️ Overlay Effect

* **Select Photos**: Choose images to apply overlay to.
* **Select Overlay Folder**: Folder containing overlay images (transparent PNG recommended).
* **Select Output Folder**: Where final images will be saved.
* **Adjust Opacity**: Control transparency of overlays.
* **Apply Overlay**: Batch process overlays on images.

---

## 📚 Dependencies Explanation

* **Pillow**: Image handling and overlay blending.
* **OpenCV**: Core image processing operations (RGB/HSV adjustments, LUT application).
* **NumPy**: Efficient pixel array manipulation.
* **Colour-science**: Reading `.cube` LUT files.
* **SciPy**: Interpolation for LUT application.

---

## 📸 Use Case Example

Perfect for:

* Photobooth services
* Social media content creators
* Event photographers
* Custom bulk image processing

---

## 📖 Notes

* Supports image formats: `.jpg`, `.jpeg`, `.png`, `.bmp`.
* LUT files must be in `.cube` format.
* Overlay images will be resized to match target photo dimensions before blending.

---

## 📜 License

This project is open-source and available under the [MIT License](LICENSE).

---

## 📧 Contact

For collaborations or custom modifications:

* Instagram: [@snap.snap.id](https://instagram.com/snap.snap.id)
