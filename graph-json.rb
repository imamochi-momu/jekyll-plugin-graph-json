# encoding: utf-8
# グラフ出力用JSONファイル
# @author 在望 もむ
# @date 2015/11/22
require 'json'
require 'neo4j-core'

# Jekyllプラグイン
module Jekyll
  # グラフ出力用JSONファイル作成
  class GraphJsonPage < Page
    # 初期化フック処理
    # @param  [String]  name  名前
    # @param  [String]  base  ベースディレクトリ
    # @param  [String]  dir  ディレクトリ
    def initialize(site, base, dir)
      @default_settings = {'path' => 'graph.json', 'level_undefined' => '未登録'}
      @site = site
      @base = base
      @dir  = dir
      if @site.config['graph-json'].nil?
        @site.config['graph-json'] = @default_settings
      end
      @path = @site.config['graph-json']['path'].nil? ? @default_settings['graph-json']['path'] : @site.config['graph-json']['path']
      @graph = {'nodes' => Array.new, 'links' => Array.new}
      @group = Array.new()
      self.process(@path)

      site.posts.docs.each do |post|
        # 存在しない場合は処理しない
        if post.data['permalink'].nil?
          next
        end
        uuid = File.basename(post.data['permalink'], ".*")
        node = @graph['nodes'].find {|item| item['uuid'] == uuid}
        if !node.nil?
          puts "duplicated uuid: " + uuid + ", url: " + post.url
          next
        end
        group = @group.find_index {|item| item == post.data['group']}
        if group.nil?
          @group.push(post.data['group'])
          group = @group.size - 1
        end
        # レベルの設定
        level = post.data['level'].nil? ? @default_settings['level_undefined'] : post.data['level'] + 'レベル'
        @graph['nodes'].push({'uuid' => uuid, 'name' => post.data['title'], 'group' => group, 'href' => post.url, 'level' => level})
        post.data['index'] = @graph['nodes'].size
      end

      site.posts.docs.each do |post|
        if post.data['permalink'].nil? || post.data['chain'].nil?
          next
        end
        uuid = File.basename(post.data['permalink'], ".*")
        target = @graph['nodes'].find_index {|item| item['uuid'] == uuid}
        if post.data['chain'].instance_of?(Array)
          post.data['chain'].each do |chain|
            source = @graph['nodes'].find_index {|item| item['uuid'] == chain}
            if !source.nil?
              @graph['links'].push({'source' => source, 'target' => target, 'value' => 1})
            end
          end
        else
          source = @graph['nodes'].find_index {|item| item == post.data['chain']}
          if !source.nil?
            @graph['links'].push({'source' => source, 'target' => target, 'value' => 1})
          end
        end
      end
      self.content = JSON.generate(@graph);
      self.data = {}
      # generate
      unless @site.config['graph-json']['neo4j'].nil?
        ssl = @site.config['graph-json']['neo4j']['host'] =~ /^https/ ? { ssl: { verify: true }} : { ssl: { verify: false }}
        session = Neo4j::Session.open(:server_db, @site.config['graph-json']['neo4j']['host'], basic_auth: { username: @site.config['graph-json']['neo4j']['username'], password: @site.config['graph-json']['neo4j']['password']}, initialize: ssl)
        session.query('MATCH (n) DETACH DELETE n')
        save_node = Array.new()
        Neo4j::Transaction.run do
          @graph['nodes'].each_index do |index|
            node = @graph['nodes'][index]
            save_node[index] = Neo4j::Node.create({uuid: node['uuid'], name: node['name'], group: node['group'], href: node['href'], level: node['level']}, 'Node')
          end
          @graph['links'].each do |link|
            p Neo4j::Relationship.create('Link', save_node[link['source']], save_node[link['target']])
          end
        end
      end
    end
  end

  # グラフ出力用ジェネレータ
  class GraphJsonPageGenerator < Generator
    safe true
    # ページ生成
    # @param  [Misc]  site    サイト情報
    def generate(site)
      site.pages << GraphJsonPage.new(site, site.source, '/')
    end
  end
end
