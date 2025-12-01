#!/usr/bin/env python3
"""Extract text from milestone-3 PDF files"""

import sys
import os

try:
    import PyPDF2
    HAS_PYPDF2 = True
except ImportError:
    HAS_PYPDF2 = False

try:
    import pdfplumber
    HAS_PDFPLUMBER = True
except ImportError:
    HAS_PDFPLUMBER = False

def extract_with_pypdf2(pdf_path):
    """Extract text using PyPDF2"""
    text = ""
    with open(pdf_path, 'rb') as f:
        pdf_reader = PyPDF2.PdfReader(f)
        for page_num, page in enumerate(pdf_reader.pages):
            text += f"\n=== Page {page_num + 1} ===\n"
            text += page.extract_text()
    return text

def extract_with_pdfplumber(pdf_path):
    """Extract text using pdfplumber (better for tables and formatting)"""
    text = ""
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages):
            text += f"\n=== Page {page_num + 1} ===\n"
            page_text = page.extract_text()
            if page_text:
                text += page_text
            # Also try to extract tables
            tables = page.extract_tables()
            if tables:
                text += "\n--- Tables ---\n"
                for table in tables:
                    for row in table:
                        if row:
                            text += " | ".join([str(cell) if cell else "" for cell in row]) + "\n"
    return text

def main():
    pdf_files = [
        "docs/milestone-3/milestone-3.pdf",
        "docs/milestone-3/pipeline.pdf"
    ]
    
    for pdf_path in pdf_files:
        if not os.path.exists(pdf_path):
            print(f"Warning: {pdf_path} not found", file=sys.stderr)
            continue
            
        print(f"\n{'='*60}")
        print(f"Extracting: {pdf_path}")
        print(f"{'='*60}\n")
        
        try:
            if HAS_PDFPLUMBER:
                text = extract_with_pdfplumber(pdf_path)
            elif HAS_PYPDF2:
                text = extract_with_pypdf2(pdf_path)
            else:
                print("Error: No PDF library available. Install pdfplumber or PyPDF2", file=sys.stderr)
                return
                
            # Save to file
            output_file = pdf_path.replace('.pdf', '.extracted.md')
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(f"# Extracted from {os.path.basename(pdf_path)}\n\n")
                f.write(text)
            
            print(f"Saved to: {output_file}")
            print(f"First 500 characters:\n{text[:500]}...")
            
        except Exception as e:
            print(f"Error extracting {pdf_path}: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    main()

