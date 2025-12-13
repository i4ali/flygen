"""
QR Code Service for Flyer Generation

Provides QR code generation and compositing onto flyer images.
Matches iOS app behavior: 15% width, 3% margin, 8px white padding.
"""
import qrcode
from PIL import Image
from pathlib import Path
from typing import Optional, Union


# QR code styling constants (matching iOS app)
QR_SIZE_PERCENT = 0.15  # 15% of flyer width
QR_MARGIN_PERCENT = 0.03  # 3% margin from edge
QR_PADDING_PX = 8  # 8px white padding around QR code


def generate_qr_code(url: str, size: int = 200) -> Image.Image:
    """
    Generate a QR code image from a URL.

    Args:
        url: The URL to encode in the QR code
        size: Target size in pixels (QR will be square)

    Returns:
        PIL Image object of the QR code
    """
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,  # High error correction (30%)
        box_size=10,
        border=0,  # We add our own white padding
    )
    qr.add_data(url)
    qr.make(fit=True)

    # Create QR code image
    qr_image = qr.make_image(fill_color="black", back_color="white")

    # Resize to target size
    qr_image = qr_image.resize((size, size), Image.Resampling.NEAREST)

    return qr_image


def composite_qr_onto_flyer(
    flyer_path: Union[str, Path],
    qr_url: str,
    output_path: Optional[Union[str, Path]] = None
) -> str:
    """
    Composite a QR code onto a flyer image at the bottom-right corner.

    Args:
        flyer_path: Path to the flyer image file
        qr_url: URL to encode in the QR code
        output_path: Optional output path. If None, overwrites the input file.

    Returns:
        Path to the output file
    """
    flyer_path = Path(flyer_path)
    if output_path is None:
        output_path = flyer_path
    else:
        output_path = Path(output_path)

    # Load flyer image
    flyer = Image.open(flyer_path)
    flyer_width, flyer_height = flyer.size

    # Calculate QR code size based on flyer dimensions
    qr_size = int(flyer_width * QR_SIZE_PERCENT)

    # Generate QR code
    qr_image = generate_qr_code(qr_url, size=qr_size)

    # Create white background with padding
    padded_size = qr_size + (QR_PADDING_PX * 2)
    white_bg = Image.new('RGB', (padded_size, padded_size), 'white')

    # Paste QR code onto white background (centered)
    white_bg.paste(qr_image, (QR_PADDING_PX, QR_PADDING_PX))

    # Calculate position (bottom-right with margin)
    margin = int(flyer_width * QR_MARGIN_PERCENT)
    x = flyer_width - padded_size - margin
    y = flyer_height - padded_size - margin

    # Ensure flyer is in RGB mode for pasting
    if flyer.mode != 'RGB':
        flyer = flyer.convert('RGB')

    # Paste QR code with white background onto flyer
    flyer.paste(white_bg, (x, y))

    # Save result
    flyer.save(output_path)

    return str(output_path)
