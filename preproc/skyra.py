#!/usr/bin/env python

import dicom
import os,re,pickle

def dicom_filetype(hdr):
    """Determine the type of image from a DICOM header."""
    scan_protocols = {
        'anatomy': ['MPRAGE','FSE','T1w','T2w','PDT','PD-T2','tse2d','mprage','t1w','t2w','t2spc','t2_spc'],
        'BOLD':['epfid'],
        'DTI':['ep_b'],
        'fieldmap':['fieldmap','field_mapping','FieldMap'],
        'localizer':['localizer','Localizer','Scout','scout'],
        'reference':['SBRef']
        }

    file_type = 'raw'
    if not hdr.ImageType[0]=='ORIGINAL':
        file_type='derived'
        return file_type
    
    for scan_type in scan_protocols.keys():
        for name in scan_protocols[scan_type]:
            if (hdr.ProtocolName.find(name) > -1) or (hdr.SequenceName.find(name) > -1) or (hdr.SeriesDescription.find(name) > -1):
               file_type = scan_type
    return file_type

def dicom_files(dcmdir):
    """Get all DICOM files in a directory."""
    files = []
    dcmext = ['.dcm','.ima']
    for f in os.listdir(dcmdir):
        (base, ext) = os.path.splitext(f)
        if ext.lower() in dcmext:
            files.append(f)
    return files

def dicom_headers(sp):
    """Read a DICOM header for all series."""
    
    dcmbase = sp.path('raw', sp.subject)
    dcmdirs = os.listdir(dcmbase)
    hdrs = {}
    dirs = {}
    for d in dcmdirs:
        dcmdir = os.path.join(dcmbase, d)
        if not os.path.isdir(dcmdir):
            continue

        # get all dicom files for this scan
        dcmfiles = dicom_files(dcmdir)

        # attempt to read the first file's header
        try:
            hdr = dicom.read_file(os.path.join(dcmdir, dcmfiles[0]))
        except:
            continue
        series = str(hdr.SeriesNumber)
        hdrs[series] = hdr
        dirs[series] = dcmdir
    return hdrs, dirs

def dicom2nifti(sp, log):
    """Convert all DICOM files to NIfTI format."""
    hdrs, dirs = dicom_headers(sp)
    for series in hdrs.keys():
        # set the output directory (based on filetype)
        filetype = dicom_filetype(hdrs[series])

        # convert to nifti
        if not filetype in ['localizer','derived','reference']:
            indir = dirs[series]
            outdir = sp.path(filetype)
            cmd = 'dcm2nii -d n -i n -o %s %s' % (outdir, indir)
            log.run(cmd)

def save_headers(sp, hdrs):
    """Save a set of headers to disk."""
    hdr_file = sp.path('logs', 'dicom_headers.pkl')
    f = open(hdr_file, 'wb')
    pickle.dump(hdrs, f)
    f.close()

def load_headers(sp):
    """Load a set of headers."""
    hdr_file = sp.path('logs', 'dicom_headers.pkl')
    f = open(hdr_file, 'rb')
    hdrs = pickle.load(f)
    f.close()
    return hdrs
    
def find_header(hdrs, nifti_file):
    """Find the header corresponding to a NIfTI file."""
    name = os.path.basename(nifti_file)
    series = name.rsplit('a')[-2].rsplit('s')[-1].lstrip('0')
    return hdrs[series]
            
def rename_bold(sp, log):
    """Rename BOLD files and move to separate directories."""
    hdrs, dirs = dicom_headers(sp)
    bold_files = sp.glob('bold', '*.nii.gz')
    for f in bold_files:
        # determine run information
        hdr = find_header(hdrs, f)

        # prep a directory for this run
        run_dir = sp.path('bold', '%s_%s' % (
            hdr.ProtocolName, hdr.SeriesNumber))
        log.run('mkdir -p %s' % run_dir)

        # move the file
        output = os.path.join(run_dir, 'bold.nii.gz')
        log.run('mv %s %s' % (f, output))
        
def rename_anat(sp, log):
    """Give anatomical scans standard names and backup intermediate files."""
    hdrs, dirs = dicom_headers(sp)
    anat_files = sp.glob('anatomy', '*.nii.gz')
    highres_ind = 1
    other_dir = sp.path('anatomy', 'other')
    log.run('mkdir -p %s' % other_dir)
    
    for f in anat_files:
        name = os.path.basename(f)
        hdr = find_header(hdrs, f)
        if hdr.ProtocolName in ['MPRAGE','mprage','t1w','T1w']:
            # this is a highres scan
            if name.startswith('c'):
                # only include the reoriented and cropped version
                output = sp.path('anatomy', 
                                 'highres%03d.nii.gz' % highres_ind)
                log.run('mv %s %s' % (f, output))
                highres_ind += 1
            else:
                log.run('mv %s %s' % (f, other_dir))
        else:
            # this is some other anatomical (such as a coronal)
            log.run('mv %s %s' % (f, other_dir))
    
