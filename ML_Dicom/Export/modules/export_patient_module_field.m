function el = export_patient_module_field(args)
%"export_patient_module_field"
%   Given a single scan, return a properly populated patient module tag
%   for use with any Composite Image IOD.  See patient_module_tags.m.
%
%   For speed, tag must be a decimal representation of the 8 digit
%   hexidecimal DICOM tag desired, ie instead of '00100010', pass
%   hex2dec('00100010');
%
%   Arguments are passed in a structure, arg:
%       arg.tag         = decimal tag of field to fill
%       arg.data        = CERR structure(s) to fill from
%       arg.template    = an empty template of the module created by the
%                         function build_module_template.m
%
%   This function requires arg.data = {'scan', scanS} OR
%                                     {'dose', doseS} OR
%                                     {'structures', structureS} OR
%
%JRA 06/19/06
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
%
%Usage:
%   dcmobj = export_patient_module_field(args)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

%Init output element to empty.
el = [];

%Unpack input data.
tag         = args.tag;
type        = args.data{1};
template    = args.template;
switch type
    case 'scan'
        %Use first scanInfo for patient information.
        scanS = args.data{2};
        dataS = scanS.scanInfo(1);
        dataS.Patient_ID = scanS.Patient_ID;
    case {'dose', 'structures'}
        dataS = args.data{2};
    otherwise
        error('Unsupported data passed to export_patient_module_field.');
end


switch tag
    %Class 1 Tags -- Required, must have data.
    
    %Class 2 Tags -- Must be present, can be blank.
    case 1048592 %0010,0010 Patient's Name
        try
            pn = org.dcm4che3.data.PersonName(dataS(1).patientName);
        catch
            if iscell(dataS.patientName.FamilyName)
                if isequal(dataS.patientName.FamilyName{1},dataS.patientName.GivenName{1}) % for anonymized data
                    patientName = dataS.patientName.FamilyName{1};
                else
                    patientName = [dataS.patientName.FamilyName{1} '^' dataS.patientName.GivenName{1} '^'];
                end
            else
                if isequal(dataS.patientName.FamilyName,dataS.patientName.GivenName)
                    patientName = dataS.patientName.FamilyName;
                else
                    patientName = [dataS.patientName.FamilyName '^' dataS.patientName.GivenName '^'];
                end
            end
            pn = org.dcm4che3.data.PersonName(patientName);
        end
        %Changed to match PersonName Component enum in dcm4che3
        
        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');
        compNamePrefix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NamePrefix');
        compNameSuffix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NameSuffix');
        
        name.FamilyName = char(pn.get(compFamilyName));
        name.GivenName  = char(pn.get(compGivenName));
        name.MiddleName = char(pn.get(compMiddleName));
        name.NamePrefix = char(pn.get(compNamePrefix));
        name.NameSuffix = char(pn.get(compNameSuffix));
        
        el = data2dcmElement(template, name, tag);
        
    case 1048608 %0010,0020 Patient ID

        %try
        %    patientID = dataS(1).DICOMHeaders.PatientID;
        %catch
        %    patientID = dicomuid;
        %end
        patientID = dataS.Patient_ID;
        el = data2dcmElement(template, patientID, tag);

    case 1048624 %0010,0030 Patient's Birth Date
 
        el = org.dcm4che3.data.Attributes;
        %el.setString(tag, template.getVR(tag), template.getString(tag));
        %vr = org.dcm4che3.data.ElementDictionary.vrOf(tag, []); %apa 6/28/19
        %vrString = char(vr); %apa 6/28/19

    case 1048640 %0010,0040 Patient's Sex

        el = data2dcmElement(template, [], tag);

        %Class 3 Tags -- presence is optional, currently undefined.
    case 1048609 %0010,0021 Issuer of Patient ID
    case 528672  %0008,1120 Referenced Patient Sequence
        
        
    case 1048626 %0010,0032 Patient's Birth Time
    case 1052672 %0010,1000 Other Patient IDs
    case 1052673 %0010,1001 Other Patient Names
    case 1057120 %0010,2160 Ethnic Group
    case 1064960 %0010,4000 Patient Comments
    case 1179746 %0012,0062 Patient Identity Removed
        %Set De-identification Method here
        
        %Class 1C Tags -- presence is required under special circumstances
    case 1179747
        %No implementation required: case 1179746 currently handles. ?? Is
        %this true?
    case 1179748
        %No implementation required: case 1179746 currently handles. ?? Is
        %this true?
    otherwise
        warning(['No methods exist to populate DICOM patient module field ' dec2hex(tag,8) '.']);
end
