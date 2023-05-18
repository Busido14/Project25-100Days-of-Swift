//
//  ViewController.swift
//  project25
//
//  Created by Артем Чжен on 17/05/23.
//

import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    var images = [UIImage]()
    
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        let buttonCamera = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        let buttonAdd = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        let buttonText = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(sendText))
        let buttonConnections = UIBarButtonItem(title: "Connection", style: .plain, target: self, action: #selector(lookToConnections))
        
        navigationItem.rightBarButtonItems = [buttonCamera, buttonText]
        navigationItem.leftBarButtonItems = [buttonAdd, buttonConnections]
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant?.start()
    }

    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)

        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }

        return cell
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
          picker.allowsEditing = true
          picker.delegate = self
          present(picker, animated: true)
      }

      func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
          guard let image = info[.editedImage] as? UIImage else { return }

          dismiss(animated: true)

          images.insert(image, at: 0)
          collectionView.reloadData()
          
          // 1
          guard let mcSession = mcSession else { return }

          // 2
          if mcSession.connectedPeers.count > 0 {
              // 3
              if let imageData = image.pngData() {
                  // 4
                  do {
                      try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                  } catch {
                      // 5
                      let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                      ac.addAction(UIAlertAction(title: "OK", style: .default))
                      present(ac, animated: true)
                  }
              }
          }
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
            ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
        
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
            
        case .connecting:
            print("Connecting: \(peerID.displayName)")
            
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
            
        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
        }
    }
    
    @objc func sendText() {
        let ac = UIAlertController(title: "Send a message", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let sendAction = UIAlertAction(title: "Send", style: .default) { [weak self, weak ac] action in
            guard let message = ac?.textFields?[0].text else { return }
            self?.submit(message)
        }
        ac.addAction(sendAction)
        present(ac, animated: true)
        
    }
    
    func submit(_ message: String) {
        guard let mcSession = mcSession else { return }
        
        if mcSession.connectedPeers.count > 0 {
            let data = Data(message.utf8)
            do {
                try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
            } catch {
                let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
    }
    
    @objc func lookToConnections() {
        guard let mcSession = mcSession else { return }
                let ac = UIAlertController(title: "Connected Users", message: nil, preferredStyle: .actionSheet)
                for user in mcSession.connectedPeers {
                    ac.addAction(UIAlertAction(title: user.displayName, style: .default))
                }
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(ac, animated: true)
    }
}

