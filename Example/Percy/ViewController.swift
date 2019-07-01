//
//  ViewController.swift
//  Percy
//
//  Created by akoulabukhov on 04/26/2018.
//  Copyright (c) 2018 akoulabukhov. All rights reserved.
//

import UIKit
import Percy

let percy = try! Percy(dataModelName: "Model")

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var liveList: LiveList<User>?
    var observer: ChangeObserver<UserAvatar>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLiveList()
        setupObserver()
    }
    
    func setupLiveList() {
        // Filter only correct emails, sort by ID ASC
        liveList = percy.makeLiveList(predicate: NSPredicate(format:"email LIKE[cd] %@", "*@*.??"), sorting: { $0.id < $1.id })
        liveList?.onChange = { [unowned self] in $0.updateTableView(self.tableView) }
        liveList?.onFinish = { [unowned self] in self.refreshFooter() }
    }
    
    func setupObserver() {
        // Observe avatar updates
        observer = percy.makeObserver()
        observer?.onChanges = { $0.forEach { print($0) } }
    }
    
    func refreshFooter() {
        tableView.footerView(forSection: 0)?.textLabel?.text = tableView(tableView, titleForFooterInSection: 0)
        tableView.footerView(forSection: 0)?.sizeToFit()
    }
    
}

// MARK: - Actions

fileprivate extension ViewController {
    
    func upsertUser(_ user: User?) {
        let alert = UpsertUserAlertFactory.makeAlert(user: user,
                    onCreate: { try! percy.create($0) },
                    onUpdate: { try! percy.update($0) },
                    onDelete: { try! percy.delete($0) },
                    onAddAvatar: { [unowned self] in try! self.setAvatarToUser($0, avatar: #imageLiteral(resourceName: "Avatar")) },
                    onRemoveAvatar: { [unowned self] in try! self.setAvatarToUser($0, avatar: nil) })
        present(alert, animated: true)
    }
    
    func setAvatarToUser(_ user: User, avatar: UIImage?) throws {
        var user = user
        user.avatar = avatar.flatMap { $0.jpegData(compressionQuality: 0.1) }
        try percy.update(user)
    }
    
    @IBAction func addUserAction(_ sender: UIBarButtonItem) {
        upsertUser(nil)
    }
    
    @IBAction func trashAction(_ sender: UIBarButtonItem) {
        // Drop livelist & observer to prevent us from handling every deleted user
        liveList = nil
        observer = nil
        try! percy.delete(entitiesOfType: User.self, predicate: nil)
        setupLiveList()
        setupObserver()
        tableView.reloadData()
    }
    
    @IBAction func composeAction(_ sender: UIBarButtonItem) {
        let actionsAlert = UIAlertController(title: "What to do?", message: "Select an action to continue", preferredStyle: .actionSheet)
        actionsAlert.popoverPresentationController?.barButtonItem = sender
        actionsAlert.addAction(.init(title: "Remove users with \"a*\" Email", style: .default) { [weak self] _ in self?.removeAEmailUsers() })
        actionsAlert.addAction(.init(title: "Create 5 random users in background", style: .default) { [weak self] _ in self?.createNewUsersInBG() })
        actionsAlert.addAction(.init(title: "Create user in another Percy and merge", style: .default) { [weak self] _ in self?.createNewUserInAnotherPercyInstance() })
        actionsAlert.addAction(.init(title: "Cancel", style: .cancel))
        present(actionsAlert, animated: true)
    }
    
    func removeAEmailUsers() {
        let predicate = NSPredicate(format: "email BEGINSWITH %@", "a")
        try! percy.delete(entitiesOfType: User.self, predicate: predicate)
    }
    
    func createNewUsersInBG() {
        // Background creation
        DispatchQueue.global().async { [percy] in
            let users = (0..<5).map { _ in User(id: .randomId(), email: .randomEmail()) }
            percy.create(users) { result in
                switch result {
                case .success: AlertController.alert(title: "Gratz!", message: "Users successfully generated").show()
                case .failure(let error): AlertController.alert(title: "Error :(", message: error.localizedDescription).show()
                }
            }
        }
    }
    
    static var tempPercy: (Percy, Percy.RemoteStoreMerger)?
    
    func createNewUserInAnotherPercyInstance() {
        let newPercy = try! Percy(dataModelName: "Model")
        let newPercyMerger = newPercy.makeRemoteStoreMerger()
        newPercyMerger.onBatchFormed = {
            ViewController.tempPercy = nil
            percy.makeRemoteStoreMerger().mergeBatch($0)
        }
        ViewController.tempPercy = (newPercy, newPercyMerger)
        try! newPercy.create(User(id: .randomId(), email: .randomEmail()))
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    var reuseIdentifier: String { return "Cell" }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return liveList?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        let user = liveList!.items[indexPath.row]
        cell.textLabel?.text = user.email
        cell.detailTextLabel?.text = user.id
        cell.imageView?.image = user.avatar.flatMap { UIImage(data: $0) }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        upsertUser(liveList?.items[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Storage size: \(ByteCountFormatter().string(fromByteCount: percy.storageSize))"
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
        let id = (arc4random() % 1000) + 1000
        return String(id) + random(maxLength: 2)
    }
    
    static func randomEmail() -> String {
        return "\(String.random(maxLength: 6))@\((String.random(maxLength: 4))).\((String.random(maxLength: 2)))".lowercased()
    }
    
}

fileprivate extension LiveList.Change {
    func updateTableView(_ tableView: UITableView) {
        switch self {
        case .inserted(_, let index): tableView.insertRows(at: [index.indexPath], with: .automatic)
        case .updated(_, _, let index): tableView.reloadRows(at: [index.indexPath], with: .automatic)
        case .deleted(_, let index): tableView.deleteRows(at: [index.indexPath], with: .automatic)
        }
    }
}

fileprivate extension Int {
    var indexPath: IndexPath { return IndexPath(row: self, section: 0) }
}
