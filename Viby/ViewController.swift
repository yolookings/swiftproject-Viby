//
//  ViewController.swift
//  Viby
//
//  Created by Maulana Ahmad Zahiri on 14/03/25.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private var recordButton: UIButton!
    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder?
    private var recordings: [Recording] = []
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioSession()
    }
    
    private func setupUI() {
        // Setup record button
        recordButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        recordButton.center = view.center
        recordButton.setTitle("Rekam", for: .normal)
        recordButton.setTitle("Berhenti", for: .selected)
        recordButton.backgroundColor = .systemRed
        recordButton.layer.cornerRadius = 50
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
        
        // Setup table view
        tableView = UITableView(frame: .zero)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecordingCell")
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        // Setup constraints
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -20)
        ])
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self?.showRecordingNotAllowedAlert()
                    }
                }
            }
        } catch {
            showRecordingNotAllowedAlert()
        }
    }
    
    @objc private func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            recordButton.isSelected = true
            
            // Add timer for updating duration
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self, self.audioRecorder != nil else {
                    timer.invalidate()
                    return
                }
                self.updateRecordingDuration()
            }
        } catch {
            stopRecording()
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        recordButton.isSelected = false
        
        if let url = audioRecorder?.url {
            let recording = Recording(url: url)
            recordings.insert(recording, at: 0)
            tableView.reloadData()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func showRecordingNotAllowedAlert() {
        let alert = UIAlertController(
            title: "Rekaman Tidak Diizinkan",
            message: "Viby membutuhkan akses ke mikrofon untuk merekam suara Anda.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateRecordingDuration() {
        guard let recorder = audioRecorder else { return }
        let duration = recorder.currentTime
        // Update UI dengan durasi
        print("Recording duration: \(duration)")
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell", for: indexPath)
        let recording = recordings[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = recording.title
        content.secondaryText = DateFormatter.localizedString(from: recording.timestamp, dateStyle: .medium, timeStyle: .short)
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = recordings[indexPath.row]
        AudioPlayer.shared.play(url: recording.url)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Hapus") { [weak self] (_, _, completion) in
            self?.deleteRecording(at: indexPath)
            completion(true)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
            self?.editRecordingTitle(at: indexPath)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    private func deleteRecording(at indexPath: IndexPath) {
        let recording = recordings[indexPath.row]
        do {
            try FileManager.default.removeItem(at: recording.url)
            recordings.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } catch {
            print("Error deleting recording: \(error.localizedDescription)")
        }
    }
    
    private func editRecordingTitle(at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Edit Judul", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.recordings[indexPath.row].title
        }
        
        let saveAction = UIAlertAction(title: "Simpan", style: .default) { [weak self] _ in
            guard let newTitle = alert.textFields?.first?.text else { return }
            self?.recordings[indexPath.row].title = newTitle
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - AVAudioRecorderDelegate
extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
        }
    }
}

