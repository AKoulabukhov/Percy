//
//  ViewController.swift
//  Percy
//
//  Created by akoulabukhov on 04/26/2018.
//  Copyright (c) 2018 akoulabukhov. All rights reserved.
//

import UIKit
import Percy

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let formatter = ByteCountFormatter()
    
    let percy = try! Percy(dataModelName: "Model")
    var observer: Observer<User>?
    
    var users = [User]()
    var storageSize: Int64 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.users = percy.getEntities(predicate: nil, sortDescriptors: nil, fetchLimit: nil)
        self.storageSize = percy.storageSize
        setupObserver()
    }
    
    func setupObserver() {
        let observer: Observer<User> = percy.observe()
        observer.onChange = { [unowned self] users, change in
            switch change {
            case .inserted: self.users.append(contentsOf: users)
            case .updated: users.forEach { user in self.indexOf(user).flatMap { self.users[$0] = user } }
            case .deleted: users.forEach { user in self.indexOf(user).flatMap { _ = self.users.remove(at: $0) } }
            }
        }
        observer.onFinish = { [unowned self] in
            self.storageSize = self.percy.storageSize
            self.tableView.reloadData()
        }
        self.observer = observer
    }
    
    func indexOf(_ user: User) -> Array<User>.Index? {
        return self.users.index(where: { $0.id == user.id })
    }
    
}

// MARK: - Actions

extension ViewController {
    
    func upsertUser(_ user: User?) {
        let percy = self.percy
        let alert = UpsertUserAlertFactory.makeAlert(user: user,
                    onCreate: { try! percy.create([$0]) },
                    onUpdate: { try! percy.update([$0]) },
                    onDelete: { try! percy.delete([$0]) },
                    onAddAvatar: { [unowned self] in try! self.setAvatarToUser($0, avatar: #imageLiteral(resourceName: "Avatar")) },
                    onRemoveAvatar: { [unowned self] in try! self.setAvatarToUser($0, avatar: nil) })
        self.present(alert, animated: true)
    }
    
    func setAvatarToUser(_ user: User, avatar: UIImage?) throws {
        var user = user
        user.avatar = avatar.flatMap { $0.jpegData(compressionQuality: 0.1) }
        try! percy.update([user])
    }
    
    @IBAction func addUserAction(_ sender: UIBarButtonItem) {
        upsertUser(nil)
    }
    
    @IBAction func trashAction(_ sender: UIBarButtonItem) {
        // Drop observer to prevent us from handling every deleted user
        self.observer = nil
        try! percy.dropEntities(ofType: User.self)
        self.users = []
        self.storageSize = percy.storageSize
        self.tableView.reloadData()
        self.setupObserver()
    }
    
    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        // Background creation
        DispatchQueue.global().async { [percy] in
            let users = (0..<1000).map { _ in User(id: .randomId(), email: .randomEmail()) }
            percy.create(users) { result in
                switch result {
                case .success: AlertController.alert(title: "Gratz!", message: "Users successfully generated").show()
                case .failure(let error): AlertController.alert(title: "Error :(", message: error.localizedDescription).show()
                }
            }
        }
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    var reuseIdentifier: String { return "Cell" }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        cell.textLabel?.text = users[indexPath.row].email
        cell.detailTextLabel?.text = users[indexPath.row].id
        cell.imageView?.image = users[indexPath.row].avatar.flatMap { UIImage(data: $0) }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        upsertUser(users[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Storage size: \(formatter.string(fromByteCount: storageSize))"
    }
    
}


// MARK: Utils

extension String {
    
    static func random(maxLength: Int) -> String {
        let wrongCharactersSet = CharacterSet(charactersIn: "-").union(.decimalDigits)
        let randomString = UUID().uuidString.components(separatedBy: wrongCharactersSet).joined()
        return String(randomString.prefix(maxLength))
    }
    
    static func randomId() -> String {
        return String.random(maxLength: 8)
    }
    
    static func randomEmail() -> String {
        return "\(String.random(maxLength: 6))@\((String.random(maxLength: 4))).\((String.random(maxLength: 2)))".lowercased()
    }
    
}
