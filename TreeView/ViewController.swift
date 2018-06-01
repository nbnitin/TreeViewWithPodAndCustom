//
//  ViewController.swift
//  TreeView
//
//  Created by Nitin Bhatia on 01/06/18.
//  Copyright © 2018 Nitin Bhatia. All rights reserved.
//

import UIKit
import RATreeView

class ViewController: UIViewController,RATreeViewDelegate,RATreeViewDataSource {

    @IBOutlet weak var containerView: UIView!
    
    //Mark:- Variables
    var treeView : RATreeView!
    var data : [DataObject]
    var editButton : UIBarButtonItem!
    var tempDataObject : DataObject!
    
    convenience init() {
        self.init(nibName : nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        data = ViewController.commonInit()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        data = ViewController.commonInit()
        super.init(coder: aDecoder)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        title = "Categories"
        setupTreeView()
        updateNavigationBarButtons()
        callApi()

    }
    
    func setupTreeView() -> Void {
        treeView = RATreeView(frame: view.bounds)
        treeView.register(UINib(nibName: String(describing: TreeTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: TreeTableViewCell.self))
        treeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        treeView.delegate = self;
        treeView.dataSource = self;
        treeView.treeFooterView = UIView()
        treeView.backgroundColor = .clear
        view.addSubview(treeView)
    }
    
    func updateNavigationBarButtons() -> Void {
        let systemItem = treeView.isEditing ? UIBarButtonSystemItem.done : UIBarButtonSystemItem.edit;
        self.editButton = UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: #selector(editButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = self.editButton;
    }
    
    @objc func editButtonTapped(_ sender: AnyObject) -> Void {
        treeView.setEditing(!treeView.isEditing, animated: true)
        updateNavigationBarButtons()
    }
    
    
    //MARK: RATreeView data source
    func treeView(_ treeView: RATreeView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? DataObject {
            return item.children.count
        } else {
            return self.data.count
        }
    }
    
    func treeView(_ treeView: RATreeView, didSelectRowForItem item: Any) {
        let x = item as! DataObject
        print(x.name)
    }
    
   
    func treeView(_ treeView: RATreeView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? DataObject {
            let x = item.children[index] as! DataObject
//            print(x.name)
            return item.children[index]
        } else {
            let x = data[index] as! DataObject
  //          print(x.name)
            return data[index] as AnyObject
        }
    }
    
   
    func treeView(_ treeView: RATreeView, cellForItem item: Any?) -> UITableViewCell {
        let cell = treeView.dequeueReusableCell(withIdentifier: String(describing: TreeTableViewCell.self)) as! TreeTableViewCell
        let item = item as! DataObject
        
        let level = treeView.levelForCell(forItem: item)
        let detailsText = "Number of children \(item.children.count)"
        cell.selectionStyle = .none
        cell.setup(withTitle: item.name, detailsText: detailsText, level: level, additionalButtonHidden: false)
        cell.additionButtonActionBlock = { [weak treeView] cell in
            guard let treeView = treeView else {
                return;
            }
            let item = treeView.item(for: cell) as! DataObject
            let newItem = DataObject(name: "Added value")
            item.addChild(newItem)
            treeView.insertItems(at: IndexSet(integer: item.children.count-1), inParent: item, with: RATreeViewRowAnimationNone);
            treeView.reloadRows(forItems: [item], with: RATreeViewRowAnimationNone)
        }
        return cell
    }
    
    //MARK: RATreeView delegate
    func treeView(_ treeView: RATreeView, commit editingStyle: UITableViewCellEditingStyle, forRowForItem item: Any) {
        guard editingStyle == .delete else { return; }
        let item = item as! DataObject
        let parent = treeView.parent(forItem: item) as? DataObject
        
        let index: Int
        if let parent = parent {
            index = parent.children.index(where: { dataObject in
                return dataObject === item
            })!
            parent.removeChild(item)
            
        } else {
            index = self.data.index(where: { dataObject in
                return dataObject === item;
            })!
            self.data.remove(at: index)
        }
        
        self.treeView.deleteItems(at: IndexSet(integer: index), inParent: parent, with: RATreeViewRowAnimationRight)
        if let parent = parent {
            self.treeView.reloadRows(forItems: [parent], with: RATreeViewRowAnimationNone)
        }
    }
    
    func callApi(){
        if let path = Bundle.main.path(forResource: "new", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                if let jsonResult: NSDictionary =  try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                {
                    print(jsonResult)
                    //  let data = jsonResult["data"] as! NSDictionary
                    
                    if ( jsonResult["success"] as! Bool ) {
                        let value = jsonResult["data"] as! NSArray
                        self.data.removeAll()
                        self.setData(response: value,obj:nil)
                        self.treeView.reloadData()
                        
                    }
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
        print("Invalid filename/path.")
        }
    }
    
    func setData(response:NSArray,obj : DataObject?,index:Int=0){
        if ( obj == nil ) {
            for i in response{
                let temp = i as! [String:AnyObject]
                var tempObj : DataObject!
                
                
                //, id: temp["id"] as! String, parentId: temp["parent_id"] as! String
                tempDataObject = DataObject(name: temp["title"] as! String)
                
                
                if ( (temp["children"] as! NSArray).count > 0 ) {
                    var index = 0
                    for j in temp["children"] as! NSArray{
                        let pol = j as! [String:AnyObject]
                        // id: pol["id"] as! String, parentId: pol["parent_id"] as! String)
                        tempDataObject.addChild(DataObject(name: pol["title"] as! String))
                        if ( (pol["children"] as! NSArray).count > 0 ) {
                            setData(response: pol["children"] as! NSArray, obj: tempDataObject.children[index],index:index)
                        }
                        index += 1
                    }
                    self.data.append(tempDataObject)
                    tempDataObject = nil
                    
                } else {
                    self.data.append(tempObj)
                }
                
            }
        } else {
            for i in response{
                let temp = i as! [String:AnyObject]
                
                //, id: temp["id"] as! String, parentId: temp["parent_id"] as! String
                tempDataObject.children.last?.addChild(DataObject(name: temp["title"] as! String))
                let ob = tempDataObject.children.last
                
                if ( (temp["children"] as! NSArray).count > 0 ) {
                    var index = 0
                    for j in temp["children"] as! NSArray{
                        let pol = j as! [String:AnyObject]
                        // id: pol["id"] as! String, parentId: pol["parent_id"] as! String)
                        ob?.children.last?.addChild(DataObject(name: pol["title"] as! String))
                        if( (pol["children"] as! NSArray).count > 0 ){
                            setData(response: pol["children"] as! NSArray, obj: obj?.children[index],index:index)
                        }
                        
                        index += 1
                    }
                    
                }
            }}
    }
    
    
    
    
    
}


private extension ViewController {
    
    static func commonInit() -> [DataObject] {
        let phone1 = DataObject(name: "Phone 1")
        let phone2 = DataObject(name: "Phone 2")
        let phone3 = DataObject(name: "Phone 3")
        let phone4 = DataObject(name: "Phone 4")
        let phones = DataObject(name: "Phones", children: [phone1, phone2, phone3, phone4])
        
        let notebook1 = DataObject(name: "Notebook 1")
        let notebook2 = DataObject(name: "Notebook 2")
        
        let computer1 = DataObject(name: "Computer 1", children: [notebook1, notebook2])
        let computer2 = DataObject(name: "Computer 2")
        let computer3 = DataObject(name: "Computer 3")
        let computers = DataObject(name: "Computers", children: [computer1, computer2, computer3])
        
        let cars = DataObject(name: "Cars")
        let bikes = DataObject(name: "Bikes")
        let houses = DataObject(name: "Houses")
        let flats = DataObject(name: "Flats")
        let motorbikes = DataObject(name: "motorbikes")
        let drinks = DataObject(name: "Drinks")
        let food = DataObject(name: "Food")
        let sweets = DataObject(name: "Sweets")
        let watches = DataObject(name: "Watches")
        let walls = DataObject(name: "Walls")
        
        return [phones, computers, cars, bikes, houses, flats, motorbikes, drinks, food, sweets, watches, walls]
        
        return []
    }
    
}







