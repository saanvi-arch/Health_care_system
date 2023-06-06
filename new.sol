pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract Hospital {
    address private hospital;
    uint private patientCount;
    uint private doctorCount;

    struct Patient {
        address patientAccount;
        uint patientID;
        string patientName;
        uint8 patientAge;
        string patientAddress;
    }

    struct Doctor {
        address doctorAccount;
        uint doctorID;
        string doctorName;
        uint8 doctorAge;
        string doctorAddress;
    }

    struct ListPatientForDoctor {
        mapping (address => bool) patientAccountIsAuthorized;
    }

    mapping (address => Patient) private patients;
    mapping (address => Doctor) private doctors;
    mapping (address => bool) private patientAccountIsRegistered;
    mapping (address => bool) private doctorAccountIsRegistered;
    mapping (address => ListPatientForDoctor) private listPatientForDoctors;

    constructor() {
        hospital = msg.sender;
        patientCount = 0;
        doctorCount = 0;
    }

    modifier onlyHospital() {
        require(msg.sender == hospital, "Unauthorized access.");
        _;
    }

    modifier onlyPatient() {
        require(patientAccountIsRegistered[msg.sender], "Patient account is not registered.");
        _;
    }

    modifier onlyDoctor() {
        require(doctorAccountIsRegistered[msg.sender], "Doctor account is not registered.");
        _;
    }

    function registerPatient(string memory _patientName, uint8 _patientAge, string memory _patientAddress) public {
        require(!patientAccountIsRegistered[msg.sender], "Patient account is already registered.");

        patientCount++;
        patientAccountIsRegistered[msg.sender] = true;
        patients[msg.sender] = Patient(msg.sender, patientCount, _patientName, _patientAge, _patientAddress);
    }

    function registerDoctor(string memory _doctorName, uint8 _doctorAge, string memory _doctorAddress) public {
        require(!doctorAccountIsRegistered[msg.sender], "Doctor account is already registered.");

        doctorCount++;
        doctorAccountIsRegistered[msg.sender] = true;
        doctors[msg.sender] = Doctor(msg.sender, doctorCount, _doctorName, _doctorAge, _doctorAddress);
    }

    function modifyPatient(string memory _patientName, uint8 _patientAge, string memory _patientAddress) public onlyPatient {
        Patient storage patient = patients[msg.sender];
        patient.patientName = _patientName;
        patient.patientAge = _patientAge;
        patient.patientAddress = _patientAddress;
    }

    function modifyDoctor(address _address, string memory _doctorName, uint8 _doctorAge, string memory _doctorAddress) public onlyHospital {
        require(doctorAccountIsRegistered[_address], "Doctor account is not registered.");

        Doctor storage doctor = doctors[_address];
        doctor.doctorName = _doctorName;
        doctor.doctorAge = _doctorAge;
        doctor.doctorAddress = _doctorAddress;

        emit Doctor_Modified(_address, _doctorName, _doctorAge, _doctorAddress);
    }

    function removePatient() public onlyPatient {
        delete patients[msg.sender];
        patientAccountIsRegistered[msg.sender] = false;
    }

    function removeDoctor(address _address) public onlyHospital {
        require(doctorAccountIsRegistered[_address], "Doctor account is not registered.");

        doctorAccountIsRegistered[_address] = false;
        delete doctors[_address];
        emit Doctor_Removed(_address);
    }

    function getPatient() public view onlyPatient returns (address, uint, string memory, uint8, string memory) {
        Patient storage patient = patients[msg.sender];
        return (patient.patientAccount, patient.patientID, patient.patientName, patient.patientAge, patient.patientAddress);
    }

    function getDoctor(address _address) public view returns (address, uint, string memory, uint8, string memory) {
        require(doctorAccountIsRegistered[_address], "Doctor account is not registered.");
        require((msg.sender == hospital) || (msg.sender == _address), "Unauthorized access.");

        Doctor storage doctor = doctors[_address];
        return (doctor.doctorAccount, doctor.doctorID, doctor.doctorName, doctor.doctorAge, doctor.doctorAddress);
    }

    function authorizePatientForDoctor(address _doctorAddress, address _patientAddress) public onlyHospital {
        require(patientAccountIsRegistered[_patientAddress], "Patient account is not registered.");
        require(doctorAccountIsRegistered[_doctorAddress], "Doctor account is not registered.");

        ListPatientForDoctor storage listPatientForDoctor = listPatientForDoctors[_doctorAddress];
        listPatientForDoctor.patientAccountIsAuthorized[_patientAddress] = true;
    }

    function cancelPatientForDoctor(address _doctorAddress, address _patientAddress) public onlyHospital {
        require(patientAccountIsRegistered[_patientAddress], "Patient account is not registered.");
        require(doctorAccountIsRegistered[_doctorAddress], "Doctor account is not registered.");

        ListPatientForDoctor storage listPatientForDoctor = listPatientForDoctors[_doctorAddress];
        listPatientForDoctor.patientAccountIsAuthorized[_patientAddress] = false;
    }

    function getAuthorizePatientForDoctor(address _doctorAddress, address _patientAddress) public view onlyHospital returns(bool) {
        require(patientAccountIsRegistered[_patientAddress], "Patient account is not registered.");
        require(doctorAccountIsRegistered[_doctorAddress], "Doctor account is not registered.");

        return listPatientForDoctors[_doctorAddress].patientAccountIsAuthorized[_patientAddress];
    }

    event Sensor_Data_Collected(address indexed _patientAccount, uint8 _patientHeartBeat, uint8 _patientBloodPressure, uint8 _patientTemperature);
    event Alert_Patient_HeartBeat(address indexed _address);
    event Alert_Patient_BloodPressure(address indexed _address);
    event Alert_Patient_Temperature(address indexed _address);

    struct Patient_Monitoring {
        address patientAccount;
        uint8 patientHeartBeat;
        uint8 patientBloodPressure;
        uint8 patientTemperature;
    }

    mapping (address => Patient_Monitoring) private patientsMonitoring;

    function setParameters(uint8 _patientHeartBeat, uint8 _patientBloodPressure, uint8 _patientTemperature) public onlyPatient {
        require(patientAccountIsRegistered[msg.sender], "Patient account is not registered.");
        require(_patientHeartBeat > 0 || _patientBloodPressure > 0 || _patientTemperature > 0, "Monitoring parameters cannot be empty.");

        Patient_Monitoring storage patientMonitoring = patientsMonitoring[msg.sender];
        patientMonitoring.patientAccount = msg.sender;
        patientMonitoring.patientHeartBeat = _patientHeartBeat;
        patientMonitoring.patientBloodPressure = _patientBloodPressure;
        patientMonitoring.patientTemperature = _patientTemperature;

        emit Sensor_Data_Collected(msg.sender, _patientHeartBeat, _patientBloodPressure, _patientTemperature);
    }

    function getParameters(address _address) public view returns (address, uint8, uint8, uint8) {
        require((msg.sender == hospital) || (listPatientForDoctors[msg.sender].patientAccountIsAuthorized[_address]) || (msg.sender == _address), "Unauthorized access.");

        Patient_Monitoring storage patientMonitoring = patientsMonitoring[_address];
        return (patientMonitoring.patientAccount, patientMonitoring.patientHeartBeat, patientMonitoring.patientBloodPressure, patientMonitoring.patientTemperature);
    }

    event Doctor_Modified(address indexed _address, string _doctorName, uint8 _doctorAge, string _doctorAddress);
    event Doctor_Removed(address indexed _address);
}