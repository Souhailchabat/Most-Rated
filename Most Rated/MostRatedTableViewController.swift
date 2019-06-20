//
//  MostRatedTableViewController.swift
//  Most Rated
//
//  Created by Souhail Chabat on 6/18/19.
//  Copyright © 2019 Souhail Chabat. All rights reserved.
//

import UIKit

struct Items: Decodable {
    let items: [Repository]
}

struct Repository: Decodable {
    let id: Int?
    let name: String?
    let owner: Owner?
    let description: String?
    let stargazers_count: Int?
}

struct Owner: Decodable {
    let login: String?
    let avatar_url: String?
}

class MostRatedTableViewController: UITableViewController {
    var repos: [Repository]?
    var avatars: [UIImage]?
    let reloadIndicator = UIRefreshControl()

    @IBOutlet weak var refreshView: UIView!
    @IBOutlet weak var refreshIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Reloading Data Indicator
        reloadIndicator.addTarget(self, action: #selector(reloadData(_:)), for: .valueChanged)
        self.tableView.addSubview(reloadIndicator)
        
        // Loading Data Indicator
        refreshIndicator.startAnimating()
        
        // Initialize Variables
        repos = [] ; avatars = []
        
        // Fetch Data
        fetchData()
    }
    
    @objc private func reloadData(_ sender: Any) {
        // Clean Up Data
        repos = [] ; avatars = []
        
        //Fetch Data
        fetchData()
    }
    
    func fetchData() {
        var base_url = "https://api.github.com/search/repositories?q=created:%3E2017-10-22&sort=stars&order=desc"
        
        // Get The Next Page
        if repos!.count != 0 {
            let pageToLoad = (repos!.count/30)+1
            base_url.append("&page=\(pageToLoad)")
        }
        
        // Create URL
        guard let url = URL(string: base_url) else { return }
        
        // Openb URLSession to Get Data
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            // Check if Data Exist
            guard let data = data else { return }
            do {
                
                // Decode the Data Fetched
                let most_rated = try JSONDecoder().decode(Items.self, from: data)
                
                // Add New Data to Array
                for item in most_rated.items {
                    self.repos?.append(item)
                    
                    // Add Image to Avatar Array
                    let image = UIImage(data: try Data(contentsOf: URL(string: (item.owner?.avatar_url)!)!))
                    self.avatars?.append(image!)
                }
                OperationQueue.main.addOperation {
                    // Reload Table
                    self.refreshView.isHidden = true
                    self.reloadIndicator.endRefreshing()
                    self.tableView.reloadData()
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        }.resume()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "repoCell", for: indexPath) as! RepoTableViewCell
        // Check if Index Exists and Load Cell
        if repos!.indices.contains(indexPath.row) {
            let currentRepo = repos![indexPath.row]
            cell.repoName.text = currentRepo.name!
            cell.repoDesc.text = validateDescription(desc: currentRepo.description)
            cell.ownerName.text = currentRepo.owner?.login!
            cell.repoStars.text = String(currentRepo.stargazers_count!)
            cell.avatarView.image = avatars![indexPath.row]
        }
        return cell
    }
    
    func validateDescription(desc: String?) -> String {
        if let desc = desc {
            return desc
        } else {
            return "No Description is available at the moment."
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 104
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Detect Last Cell and Load More Data
        if indexPath.row == repos!.count-1 { fetchData() ; self.refreshView.isHidden = false }
    }
    
}


